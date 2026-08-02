# Phase 2 — 渲染与输入核心（手感闭环）

> 版本: v1.0 | 日期: 2026-08-02 | 状态: 待工人执行
> 前置: Phase 1 契约层全部通过审核（T-001~T-007）

---

## 1. 阶段目标

在 HarmonyOS 模拟器上实现"笔触屏幕 → 看到笔迹"的完整闭环，包含：
- 压感/倾斜采集
- Force smoothing + 三次贝塞尔拟合
- 可变宽度填充轮廓（一步到位，参照 `w4a.b()`）
- PencilSplat 铅笔纹理（完整 §18 公式）
- 橡皮擦（PARTIAL + WHOLE）
- 低延迟分层架构（已完成层 + 当前笔画层 + 脏矩形）

**完成标准**：在模拟器上用触摸/笔绘制笔画，可见平滑笔迹、铅笔纹理、压感变化和擦除效果。

---

## 2. 架构设计

```
┌─ NoteCanvasPage (ArkUI) ─────────────────────────────┐
│  Canvas 组件 (onReady / onTouch)                      │
│    ├── 输入: TouchEvent → RawPointerEvent[]           │
│    │         → InkInputProviderImpl.processEvent()    │
│    │         → InputBatch                             │
│    ├── 几何: StrokeSession                            │
│    │         ├── ForceSmoother (力平滑)               │
│    │         ├── CubicFitter (贝塞尔拟合)             │
│    │         └── WidthOutlineBuilder (可变宽度轮廓)   │
│    ├── 铅笔: PencilSplatGenerator (splat 散布)       │
│    ├── 渲染: Canvas2DStrokeRenderer                   │
│    │         ├── 中心线路径 (Mono/Dash/Dot)           │
│    │         ├── 可变宽度填充 (Taper)                 │
│    │         ├── PencilSplat (OffscreenCanvas+source-in)│
│    │         └── 擦除遮罩 (clipOut)                   │
│    └── 层管理: StrokeLayerManager                     │
│              ├── 已完成层 (OffscreenCanvas 缓存)      │
│              ├── 当前笔画层 (实时重绘)                │
│              └── DirtyRectTracker (脏矩形)            │
└──────────────────────────────────────────────────────┘
```

### 数据流

```
TouchEvent
  → RawPointerEvent[] (真实+历史)
  → InkInputProviderImpl → InputBatch(REAL/HISTORICAL)
  → StrokeSession.addBatch()
      → ForceSmoother.smooth(points) → smoothedPoints
      → CubicFitter.fit(smoothedPoints, tolerance) → CubicSegment[]
      → WidthOutlineBuilder.build(centerline, widthFactors, baseWidth) → Path2D
      → [铅笔] PencilSplatGenerator.generate(curve, spacing, pressure...) → PencilSplatPoint[]
  → Canvas2DStrokeRenderer.render(stroke, ctx)
  → [完成] StrokeLayerManager.commitStroke() → 合并到已完成层
```

---

## 3. 模块边界与文件规划

```
note/src/main/ets/core/algorithm/
├── ForceSmoother.ets           // T-009
├── CubicFitter.ets             // T-009
├── WidthOutlineBuilder.ets     // T-010
├── PencilSplatGenerator.ets    // T-011
└── ShapeDetector.ets           // Phase 3（本阶段不实现）

note/src/main/ets/core/adaptation/
├── InkInputProviderImpl.ets    // T-008（InkInputProvider 实现）
├── Canvas2DStrokeRenderer.ets  // T-012（StrokeRenderer 实现）
├── PenKitPredictor.ets         // T-008（Predictor 实现）
└── NullPredictor.ets           // T-008（Predictor 空实现）

note/src/main/ets/rendering/
├── StrokeLayerManager.ets      // T-013
├── DirtyRectTracker.ets        // T-013
├── StrokeSession.ets           // T-014（进行中笔画状态机）
└── EraserEngine.ets            // T-014

note/src/main/ets/ui/editor/
└── NoteCanvasPage.ets          // T-015（画布页面 + 事件绑定）
```

---

## 4. 核心算法规格（工人必须精确实现）

### 4.1 Force Smoother（§17）

| 参数 | 值 | 来源 |
|------|-----|------|
| enabled | true | dr4 构造器 |
| smoothing window | 8 ms | dr4 参数 |
| 单点最大 force 变化 | 0.15 | dr4 参数 |

逻辑：对连续输入点的 pressure 值做窗口平滑，限制相邻点 force 变化不超过 0.15。

### 4.2 三次贝塞尔拟合（§17 sqh）

| 参数 | 值 |
|------|-----|
| 单次拟合最大点数 | 200 |
| 上下文扩展 | 前后各 5 点 |
| 病态回退 | 直线三等分控制点 |

算法步骤：
1. `sqh.g()`：构造三次 Bernstein 基函数，解 2×2 正规方程求 p1/p2
2. `sqh.h()`：逐点采样曲线，计算最大欧氏误差；超 tolerance 则拒绝
3. `sqh.f()`：二分查找最长可接受区间，分段继续

动态容差（§17 公式）：
```
tolerance = (0.5 / ((((dd4.d(width * scale) - 2.6) / 15.4) * 1.5) + 1.0)) / scale
```
其中 `width` = 基础笔宽，`scale` = 当前缩放。`dd4.d()` 待确认，MVP 先用 `Math.log` 近似。

### 4.3 可变宽度轮廓（§23/§35 w4a.b()）

输入：中心线点序列 + 逐点 widthFactor + baseWidth
输出：填充 Path（封闭多边形）

算法核心：
1. 对每个中心线点，计算局部半宽 `halfWidth = widthFactor * baseWidth / 2`
2. 计算该点的法向量（垂直于切线方向）
3. 上轮廓 = 中心线 + 法向量 × halfWidth
4. 下轮廓 = 中心线 - 法向量 × halfWidth
5. 封闭路径 = 上轮廓正序 + 下轮廓逆序
6. 端点处理：起点/终点用半圆帽（round cap）
7. 尖角处理：相邻法向量夹角过大时插入扇形过渡

### 4.4 PencilSplat 生成（§18 完整公式）

```
// 压感→尺寸
sizePressure = 1 - (1 - min(pressure, 2)/2)⁵
sizeTilt     = 1 - (min((tilt - π/2) / (-0.94248), 1))⁵
sizeFactor   = sizePressure * sizeTilt + (1 - sizeTilt) * 1.0

// 散布盘
scaleBase = min(width, 2)/2 * 0.97 + 0.03
angleDiff = max(π/5 - orientation, 0)
splatCount = floor(angleDiff / (π/125)) + 1    // 最多 26

// LCG 确定性随机
seed = (seed * 1118393071) % 1946926193

// 每 splat
θ = rand * 2π
r = sqrt(rand)           // 均匀盘
x = 0.9 * cos(θ) * r    // 椭圆收缩
rotation = rand * 2π
opacity = (1 - sqrt(r)) * edgeFactor * scaleBase
```

### 4.5 Canvas 2D PencilSplat 渲染（§37）

```
1. 加载 splat 纹理 → ImageBitmap / PixelMap
2. 对每个 splat:
   a. OffscreenCanvas: drawImage(纹理, 0, 0) 带 translate/rotate/scale
   b. globalCompositeOperation = 'source-in'
   c. fillStyle = 笔色 → fillRect 着色
3. 主 Canvas: drawImage(offscreen) 合成
4. 颜色缓存: Map<number, OffscreenCanvas>
```

### 4.6 低延迟层管理（§19 鸿蒙适配）

| 层 | 实现 | 内容 |
|----|------|------|
| 已完成层 | OffscreenCanvas（全页尺寸） | 所有已完成笔画的累积渲染 |
| 当前笔画层 | 主 Canvas 上直接绘制 | 进行中笔画（每帧清空重绘） |
| 合成 | 主 Canvas: drawImage(已完成层) + 当前笔画 | 每帧 |

笔画完成时：
1. 将当前笔画渲染到已完成层 OffscreenCanvas
2. 清空当前笔画状态
3. 脏矩形 = 笔画 bounds ± 3px

---

## 5. 涉及鸿蒙 API 与权限

| API | 起始版本 | SystemCapability | 用途 |
|-----|----------|------------------|------|
| Canvas + CanvasRenderingContext2D | 8 | 无特殊 | 2D 渲染 |
| OffscreenCanvas | 9 | 无特殊 | 层缓存/splat 着色 |
| TouchEvent (TouchPoint) | 7 | 无特殊 | 输入采集 |
| PointPredictor (@kit.Penkit) | 5.0.0(12) | SystemCapability.Stylus.Handwrite | 预测点（可选） |
| image.PixelMap | 9 | 无特殊 | splat 纹理加载 |

权限：无额外权限（Pen Kit 为系统能力声明，非用户授权）。

---

## 6. 任务卡拆分

| 卡号 | 名称 | 依赖 | 产出 |
|------|------|------|------|
| T-008 | 输入采集实现 | Phase 1 | InkInputProviderImpl + PenKitPredictor + NullPredictor |
| T-009 | Force Smoother + 三次贝塞尔拟合 | T-008 | ForceSmoother.ets + CubicFitter.ets |
| T-010 | 可变宽度轮廓算法 | T-009 | WidthOutlineBuilder.ets |
| T-011 | PencilSplat 生成器 | T-009 | PencilSplatGenerator.ets |
| T-012 | Canvas 2D 渲染器 | T-010, T-011 | Canvas2DStrokeRenderer.ets |
| T-013 | 层管理与脏矩形 | T-012 | StrokeLayerManager.ets + DirtyRectTracker.ets |
| T-014 | 笔画会话与橡皮擦 | T-013 | StrokeSession.ets + EraserEngine.ets |
| T-015 | 画布页面集成 | T-014 | NoteCanvasPage.ets（可运行闭环） |

### 依赖图

```
T-008 (输入) → T-009 (平滑+拟合) ─┬→ T-010 (可变宽度)
                                   └→ T-011 (PencilSplat)
                                         ↓
T-010 + T-011 → T-012 (渲染器) → T-013 (层管理) → T-014 (会话+擦除) → T-015 (页面)
```

**建议执行顺序**：严格 T-008 → T-009 → T-010/T-011（可并行）→ T-012 → T-013 → T-014 → T-015

---

## 7. 验收基准（模拟器阶段）

| 项 | 标准 | 验证方式 |
|----|------|----------|
| 笔画可见 | 触摸/笔滑动后出现平滑笔迹 | 模拟器运行 + UI 树 |
| 压感响应 | 模拟器压力滑块变化 → 笔宽变化 | 手动测试 |
| 铅笔纹理 | PencilSplat 散布可见，非简单线条 | 视觉对比 |
| 可变宽度 | Taper 笔画起粗收细（或压感变化） | 视觉验证 |
| 橡皮擦 | PARTIAL 挖洞 + WHOLE 整条消失 | 手动测试 |
| 无崩溃 | 连续绘制 30 秒无异常 | hilog 检查 |
| 编译通过 | check_ets_files + build_project | MCP 自动化 |

**注意**：延迟/掉帧指标在模拟器阶段不做硬性要求，标注"待真机"。

---

## 8. 约束提醒

- 算法模块（`core/algorithm/`）禁止 import 平台 API，保持纯数学。
- 渲染实现（`Canvas2DStrokeRenderer`）可以 import Canvas 相关类型（它是适配层实现）。
- `NoteCanvasPage.ets` 是 UI 组件，使用 `@Entry @Component` 装饰器。
- PencilSplat 纹理图片需要放到 `note/src/main/resources/rawfile/` 下（T-011 需要生成或放置一张 splat 纹理 PNG）。
- 所有算法参数必须可配置（通过构造器参数或配置对象），不硬编码在方法体内。
