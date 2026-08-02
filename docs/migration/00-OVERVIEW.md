# Notability → HarmonyOS 移植总纲

> 版本: v0.1-draft | 日期: 2026-08-02 | 状态: 待用户确认
> 本文档由移植指挥官独占维护；工人不得修改。

---

## 1. 项目目标与体验标准

### 1.1 目标

将 Notability Android 1.0.1 的核心笔记体验移植到 HarmonyOS 平板，深度适配华为手写笔（M-Pencil），产出可独立运行的鸿蒙原生应用。

### 1.2 体验标准（第一优先级：手写手感）

| 维度 | 标准 | 验收方式 |
|------|------|----------|
| 铅笔纹理质感 | PencilSplat 算法完整复现（LCG 随机 + 椭圆盘 + 压感⁵缓动） | 与原版同轨迹截图差分 |
| 压感响应 | 轻重过渡自然，归一化 [0,1] 后映射到 scale/opacity | 真机多压力级采样对比 |
| 倾斜侧锋 | 铅笔倾斜时变粗变淡 | 真机倾斜角采集 + 视觉对比 |
| 低延迟 | 目标 P95 < 16ms（不预设达成，必须真机量测） | 高速摄像/帧时间戳量测 |
| 笔画平滑 | 快速书写不抖动不折线 | Force smoothing + 三次贝塞尔拟合 |
| 可变宽度 | Taper/逐点宽度因子 → 填充轮廓 | 与原版同数据渲染对比 |

**原则**：仅凭硬件规格不能推导最终手写体验；输入采样、预测、渲染调度、屏幕刷新率和笔刷算法都必须在目标设备上联合量测。

---

## 2. 分阶段里程碑

### Phase 1 — 数据模型与契约层（ foundation ）

**目标**：定义全部跨阶段共享的类型、接口、枚举和数据库 schema，让后续阶段可以并行开工。

| 交付物 | 说明 |
|--------|------|
| 元素模型 | StrokePoint / StrokeElement / PencilSplat / TextBlock / 形状（Line/Ellipse/Polygon） |
| op 流模型 | OpType 枚举 / Op 序列化接口 / OpStore 接口 |
| 适配层三接口 | InkInputProvider / StrokeRenderer / Predictor（§40 已设计） |
| 渲染规格 | BrushSpec / InkStyle / WetMirrorRenderSpec 等价类型 |
| 数据库 schema | relationalStore DDL（NoteState / ToolState / ClientOp / NoteAsset / SyncedNoteMetadata） |
| 资源引用 | AssetHash / AssetStatus 模型 |

**完成标准**：所有 .ets 接口/类型文件编译通过；工人可只看契约文件开始 Phase 2 实现。

### Phase 2 — 渲染与输入核心（手感闭环）

**目标**：在真机/模拟器上实现"笔触屏幕 → 看到笔迹"的完整闭环，包含铅笔纹理和压感。

| 交付物 | 说明 |
|--------|------|
| 输入采集 | TouchEvent 真实点 + 历史点 + PointPredictor 预测点（分轨） |
| Force Smoother | 8ms 窗口 + 0.15 最大 force 变化 |
| 三次贝塞尔拟合 | 最小二乘 + 动态容差 + 二分最长区间 |
| 固定宽度渲染 | Mono/Dash/Dot 中心线 Canvas 2D Path |
| 可变宽度渲染 | 中心线 → 填充轮廓（对照 `w4a.b()`） |
| PencilSplat 生成 | 完整公式（§18）：确定性 LCG + 椭圆盘 + 压感⁵ |
| PencilSplat 渲染 | Canvas 2D OffscreenCanvas + source-in 着色 |
| 橡皮擦 | PARTIAL（clipOut 挖洞）+ WHOLE（整条删除） |
| 低延迟架构 | 已完成层缓存 + 当前笔画层 + 脏矩形重绘 |
| 延迟基准报告 | P50/P95/掉帧，分别记录开/关预测和帧加速 |

**完成标准**：同一条轨迹在鸿蒙端和原版渲染视觉可接受；延迟基准报告产出。

### Phase 3 — 工具系统与交互 UI

**目标**：完整工具栏、笔记库、多页管理、选区变换、响应式布局。

| 交付物 | 说明 |
|--------|------|
| 工具栏 | Pen/Pencil/Highlighter/Eraser/Selection + 颜色/粗细面板 |
| 双层导航 | LibraryPage → NotePage（主栈 + 笔记内部栈分离） |
| 资料库 | 文件夹/笔记列表/网格/搜索 + 600/840/952/1400vp 断点 |
| 多页管理 | 页面增删/排序/尺寸（A4/Letter...）/纸张模板 |
| 选区工具 | 矩形 + 套索 + 22 项菜单操作 + 统一 transform |
| 形状工具 | 笔画完成 → 直线/椭圆/多边形识别替换 |
| Undo/Redo | 基于 op 栈的撤销/重做 |
| 文本框 | 创建/编辑/排版/统一变换 |

**完成标准**：核心交互流可走通（新建笔记 → 多工具书写 → 选区变换 → 多页 → 返回库）。

### Phase 4 — 备份与 WebDAV 同步（差异化特性）

**目标**：实现 .note ZIP 包导出/导入 + WebDAV 云备份，原版没有的差异化能力。

| 交付物 | 说明 |
|--------|------|
| .note 包格式 | ZIP（元数据 JSON + op 流二进制 + 资源文件） |
| 导出/导入 | 完整笔记 ↔ .note 文件 |
| WebDAV 客户端 | @ohos.net.http + 标准 WebDAV 协议 |
| 自动备份 | 后台任务 + 增量同步 |
| 恢复 | 从 WebDAV 拉取 + 冲突处理 |

**完成标准**：笔记可导出为 .note → 从另一台设备导入还原；WebDAV 自动备份/恢复可演示。

---

## 3. 全局技术选型（锁定）

| 领域 | 选型 | 依据 |
|------|------|------|
| 语言 | ArkTS（严格模式） | HarmonyOS 原生 |
| UI 框架 | ArkUI 声明式 | 官方推荐 |
| SDK | HarmonyOS 6.0.1(21) | 当前工程 build-profile.json5 |
| 目标设备 | tablet（MatePad 系列） | module.json5 deviceTypes |
| 渲染路线 | Canvas 2D → ShaderEffect(API20+) → XComponent/OpenGL ES | §37 三层验证 |
| 输入 | TouchEvent + Pen Kit PointPredictor(5.0.0(12)+) | §36 |
| 帧加速 | StylusFrameBoost(API26 Beta，可选) | §36，不阻塞正确性 |
| 数据库 | @ohos.data.relationalStore | 替代 Room |
| 状态管理 | @State/@Observed/@ObjectLink + 自研 Store | 轻量、无三方依赖 |
| 网络 | @ohos.net.http | WebDAV |
| 后台任务 | @ohos.backgroundTaskManager | 备份调度 |
| 依赖管理 | OHPM | 工程已有 |
| 测试 | @ohos/hypium + @ohos/hamock | 工程已有 |

### 不引入的依赖

- MyScript（MVP 不集成手写识别）
- PDFTron（后续按需评估 PDF Kit）
- Rive（动画后续评估）
- 任何 Android .so 二进制

---

## 4. 全局接口契约清单

> 以下接口在 Phase 1 定义，跨阶段共享。工人不得修改契约签名；如需扩展，向指挥官申请。

### 4.1 适配层三接口（§40 架构）

```
文件: note/src/main/ets/core/adaptation/
├── InkInputProvider.ets      // 笔事件采集抽象
├── StrokeRenderer.ets        // 笔迹渲染抽象
└── Predictor.ets             // 低延迟预测点抽象
```

| 接口 | 核心方法 | 职责 |
|------|----------|------|
| InkInputProvider | `onTouchEvent(event): InputBatch` | 采集坐标/压感/倾斜/方位角/时间戳，分轨真实/历史/预测 |
| StrokeRenderer | `renderStroke(stroke, ctx): void` / `renderSplat(splats, spec, ctx): void` | 渲染笔画到画布 |
| Predictor | `predict(history: InputPoint[]): InputPoint[]` | 生成预测点（可空实现） |

### 4.2 数据模型类型

```
文件: note/src/main/ets/core/model/
├── StrokeTypes.ets           // InputPoint / StrokePoint / StrokeElement / PencilSplatPoint
├── BrushTypes.ets            // BrushSpec / InkStyle / BrushStyle / ToolType
├── ElementTypes.ets          // NoteElement 联合类型 / ElementType 枚举
├── OpTypes.ets               // OpType 枚举 / Op 接口 / OpPayload 类型
├── NoteTypes.ets             // NoteMeta / PageInfo / PaperTemplate / PaperSize
└── AssetTypes.ets            // AssetHash / AssetStatus / NoteAsset
```

### 4.3 数据库契约

```
文件: note/src/main/ets/data/
├── DatabaseHelper.ets        // relationalStore 初始化 + DDL + 版本迁移
├── NoteRepository.ets        // 笔记 CRUD 接口
├── OpRepository.ets          // op 流读写接口
└── AssetRepository.ets       // 资源管理接口
```

### 4.4 渲染规格

```
文件: note/src/main/ets/rendering/
├── RenderSpec.ets            // WetMirrorRenderSpec 等价（color/width/style/isHighlighter/isPencil）
├── PaperRenderer.ets         // 纸张模板程序化绘制接口
└── SplatRenderer.ets         // PencilSplat 渲染器接口
```

---

## 5. 工程目录规划

```
note/src/main/ets/
├── core/                     // 核心层（平台无关）
│   ├── adaptation/           // 适配层接口 + 实现
│   │   ├── InkInputProvider.ets
│   │   ├── StrokeRenderer.ets
│   │   ├── Predictor.ets
│   │   ├── Canvas2DRenderer.ets      // 实现 A
│   │   └── PenKitPredictor.ets       // 实现 A
│   ├── model/                // 数据模型（纯类型，无平台 import）
│   ├── algorithm/            // 算法模块
│   │   ├── ForceSmoother.ets
│   │   ├── CubicFitter.ets
│   │   ├── PencilSplatGenerator.ets
│   │   ├── VariableWidthOutline.ets
│   │   └── ShapeDetector.ets
│   └── op/                   // op 流引擎
│       ├── OpEngine.ets
│       └── OpSerializer.ets
├── data/                     // 数据层
│   ├── DatabaseHelper.ets
│   ├── NoteRepository.ets
│   ├── OpRepository.ets
│   └── AssetRepository.ets
├── rendering/                // 渲染层
│   ├── RenderSpec.ets
│   ├── PaperRenderer.ets
│   ├── SplatRenderer.ets
│   ├── StrokeLayerManager.ets
│   └── DirtyRectTracker.ets
├── ui/                       // UI 层
│   ├── library/              // 资料库页面
│   ├── editor/               // 编辑器页面
│   │   ├── NoteCanvasPage.ets
│   │   ├── Toolbar.ets
│   │   └── ToolRail.ets
│   ├── components/           // 共享组件
│   └── theme/                // 主题 token
├── pages/                    // 路由入口
│   └── Index.ets
├── noteability/
│   └── NoteAbility.ets
└── notebackupability/
    └── NoteBackupAbility.ets
```

---

## 6. 协作规则（指挥官 + 工人必读）

1. **指挥官不写业务代码；工人不做架构决策。**
2. **工人遇到任务卡未覆盖的决策 → 停下来问指挥官，禁止自己拍板或改契约。**
3. **单一写入者**：指挥官独占 `docs/migration/` 架构文档；工人只改 `note/` 下实现代码 + 写完成报告到 `docs/migration/reports/`。
4. **每个任务卡必须有可客观判定的验收标准**；工人自检后，指挥官验收并更新任务状态。
5. **任务粒度** = 一个可独立编译/验证的单元；宁可把卡写啰嗦，也不给一句话任务。
6. **沿用证据等级**：✅ 闭环 | 🟡 主体确认有缺口 | ⚠️ 线索推断 | ❓ 待定位。性能结论（如延迟 <16ms）必须真机量测，不得预设达成。

---

## 7. 鸿蒙特有约束（相关任务卡必须标注）

| 约束 | 说明 |
|------|------|
| ArkTS 严格类型 | 无 any、显式类型、用装饰器（@Entry/@Component/@State/@Observed） |
| API 版本标注 | 每个用到的 API 标注起始版本与 SystemCapability |
| SDK 区分 | 区分华为 HarmonyOS SDK 与 OpenHarmony 上游能力（Pen Kit 是华为专有） |
| 渲染路线锁定 | §37 三层结论；AGSL 不可直接迁移 |
| 响应式布局 | 用 vp/fp，保留 600/840/952/1400 断点语义，不硬编码像素 |
| 权限声明 | 使用 Pen Kit 需 `SystemCapability.Stylus.Handwrite`；帧加速需 `ohos.permission.STYLUS_FRAME_BOOST` |
| 适配层隔离 | 业务代码禁止直接 import `@ohos.*` 平台 API，只能经适配层 |

---

## 8. 落盘与提交纪律

| 规则 | 说明 |
|------|------|
| 文档位置 | 所有 Plan/任务卡写进 `docs/migration/` |
| 提交格式 | `plan: <内容>` / `impl(T-NNN): <内容>` |
| 里程碑 tag | 每个 Phase 完成打 tag：`phase-N-complete` |
| 任务卡编号 | `docs/migration/tasks/T-NNN-<名称>.md`，三位数递增 |
| 完成报告 | `docs/migration/reports/T-NNN-完成.md` |

---

## 9. 风险与降级策略

| 风险 | 影响 | 降级 |
|------|------|------|
| Canvas 2D PencilSplat 性能不足 | 铅笔渲染掉帧 | 升级 ShaderEffect(API20+) 或 XComponent/OpenGL ES |
| PointPredictor 设备不支持 | 延迟升高 | 空实现 Predictor，用简单线性外推 |
| 可变宽度轮廓算法复杂度高 | Phase 2 延期 | MVP 先固定宽度 + Taper 尾部三角降级，标注为功能降级 |
| 真机未到位 | 无法量测延迟/压感 | 模拟器先验证正确性，性能指标标"待真机" |
| op 流顶层分发未完全逆向 | 数据模型可能有缺口 | 先按已确认的元素 schema 实现，预留扩展点 |

---

## 10. 事实优先级

```
反编译代码 / 华为官方文档 > REVERSE_ANALYSIS.md 带证据结论 > COMMANDER.md 状态 > 历史对话
```

---

## 11. 参考文档索引

| 文档 | 用途 |
|------|------|
| `docs/REVERSE_ANALYSIS.md` §4-6 | 渲染/输入/笔画模型 |
| `docs/REVERSE_ANALYSIS.md` §17-19 | 平滑/PencilSplat/低延迟 |
| `docs/REVERSE_ANALYSIS.md` §21 | op 流持久化 |
| `docs/REVERSE_ANALYSIS.md` §37 | 纹理渲染三层路线 |
| `docs/REVERSE_ANALYSIS.md` §39 | UI 入口与移植地图 |
| `docs/REVERSE_ANALYSIS.md` §40 | 适配层架构 |
| `reference/java/audit_cxe/cxe.java` | 画布编辑器核心类 |
| `reference/java/audit_ys0/ys0.java` | 输入事件分发 |
| `reference/decompiled/gingerlabs/notability/` | 业务 Java 参考 |

---

*等待用户确认后，指挥官将细化 Phase 1 阶段设计与任务卡。*
