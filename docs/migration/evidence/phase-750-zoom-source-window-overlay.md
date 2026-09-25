# Phase 750 证据：原版 Zoom 源窗口覆盖层（gfg/dfg/bfg）+ vp2px 坐标修复

> 证据基线：`decompiled_1.0.3`（JADX 输出，`C:\Users\Cisco He\Desktop\Notability\` 只读）。
> 关联：ADR-0695（Zoom 面板移植）、ADR-0696（整页渲染）、ADR-0697（前进区宽度持久化）。

## 1. 原版覆盖层存在性

`defpackage/gfg.java`：ZOOM 激活时叠加在页面上的可组合函数。
其 `a(...)` 方法体内通过 `pd8`/`q8e` 把页面内容包装进 pointerInput 修饰符，
并安装 `efg`（`PointerInputEventHandler`）。`efg.invoke` 转调 `dih.q(bra, new dfg(...))` —
`dfg` 是多点协程拖拽状态机（`invokeSuspend` 超过 JadxOverflowException 上限，
方法体未反编译，手势精确数学不可恢复）。

`gfg` 中注册的委托回调（394 行内）：

```
htd  → ahg.setSourceRect(Rect)              // 窗口移动
ikf  → ahg.resizeSourceRect(Rect, float)    // 窗口缩放 + 倍率联动（两处）
```

`ahg.i(cmb, f)`（mask=51，参数 3+4）：**同帧同时写入 sourceRect 与 magnification**——
证明原版窗口缩放与放大倍率耦合：窗口在屏幕上被拉大 ⇒ doc 窗口变宽 ⇒
magnification 下降（放大面仍充满面板宽）。

`bfg`（`gfg` 内 `m18.k` 挂载的 LaunchedEffect 协程）：窗口可见性/动画状态管理，
字段含 `gl8`（State<Boolean>）与 `vj8`（InteractionSource）——按压反馈存在。

## 2. 覆盖层视觉（res/drawable/ui_designsystem__zoom_*.xml）

| Drawable | 结构 |
|---|---|
| `zoom_fill` | 黑色实心圆角方片（24×24dp，radius≈2dp）——把手 chip 的基底/阴影 |
| `zoom_overlay` | 白色圆角方片，**内部挖去一圆**（evenOdd：rect − circle(9.32,14.32,r5.32)）|
| `zoom_outline` | 黑色描边圆角框，**左下角留缺口**（底边从 x=5.5 起笔、左边到 y=18.5 止笔）|
| `zoom_highlight` | 白色局部填充（chip 玻璃高光）|
| `zoom_shadow` | 黑色底缘投影 |
| `zoom_advance_tab` | 前进区中央小 tab（已在面板层覆盖，`Phase 747`）|

`gfg.b` = 多边形点表 `[(14,2),(8,8),(8,8),(8,14),(2,14),(14,14)]`——
把手内圈握持指示形状。

结论：把手 chip 定位于**窗口左下角**（outline 缺口即 chip 占位的圆角框开口）。

`gfg.a` 常量：`iu1.b(0.08f)` → 8% 暗化（窗口外遮罩 alpha）。

## 3. `hhf` 的真实语义（修正调查方向）

`hhf` 是双模式 PointerInputEventHandler：

- `a=0` 分支：速度阈值 fling 检测（`u8e.a()*100` px/s、`ix4Var(sign)` 回调 +
  `t33`/`fb8` 协程）——对应**面板拖拽柄的甩动停靠**（非旋转手势）。
- `a=1` 分支（默认）：包装 `ffg` —— 另一 `invokeSuspend` 未反编译的拖拽状态机
  （`oqa`/`whf`/`cmb` 字段，窗口/前进区二级拖拽）。

早前调查曾推测 `hhf` 为旋转/扭转手势——经完整反编译体确认为误判，
实为速度 fling + 二级拖拽包装器。

## 4. Harmony 移植映射

| 原版 | Harmony（Phase 750） |
|---|---|
| `gfg` 覆盖层组合 | `renderZoomWindowOverlay()` — renderFrame 尾部屏幕空间绘制 |
| `iu1.b(0.08f)` 遮罩 | `#14000000` 四矩形拼接遮罩（窗口区留空） |
| `zoom_outline` 描边框 | 2vp 圆角、1.5vp 黑描边（缺口由不透明 chip 覆盖，等价近似） |
| `zoom_fill/overlay/highlight` 把手 | 左下角 24vp 白色圆角 chip + 深色圆环 + 投影 |
| `dfg` 窗内拖动 → `setSourceRect` | 窗内拖动：`source += screenDelta/zoom` → `clampZoomSource` |
| `dfg` 把手拖动 → `resizeSourceRect` | 把手拖动：右上缘锚定，`mag = min(surfaceW/candW, surfaceH/candH)`，clamp [1,10] |
| `dfg` 窗外点按 | 窗口中心跳到触点并进入 MOVE（经典 zoom-box 行为，近似） |
| `hhf` fling 停靠 | 未移植：Harmony 停靠走落点判定（Phase 747 已登记近似） |
| 窗口外触摸消费 | `onCanvasTouch` 顶层路由——ZOOM 激活时元素点按不再触发 |

## 5. 顺带修复：vp2px 坐标缺陷（Phase 747 移植 bug）

**根因**：`CanvasRenderingContext2D` 构造未传 `unit` → 默认
`LengthMetricsUnit.DEFAULT` = **vp** 绘制空间。触摸 `touch.x/y`、
`ctx.width`、viewport scroll/zoom 全部 vp 空间自洽。
Phase 747 按"ctx 为 px"假设加入了四处 `vp2px()`：

| 位置 | 后果（density≈2.75 时） |
|---|---|
| `zoomDocPoint` 两处 | 放大面板笔画落点偏离约 2.75×——**书写位置明显错误** |
| `zoomSurfaceRectWidth/HeightDoc` | doc 窗口尺寸虚增 → 源窗/前进区/步进计算整体偏移 |
| `zoomAdvanceDoc` | 前进区 doc 宽虚增 → 自动前进提前触发 |
| `NoteZoomView` advancePx/tabW/tabH | 前进区阴影带与 tab 标记放大约 2.75× |
| `zoomSurfaceRectWidthDoc` 用 `overlayWidth` | overlayWidth=主画布宽，面板实为 `overlayWidth−16`（margin 8×2） |

修复：全部改为 vp 直值（除以 magnification 换算 doc），面板宽修正为
`overlayWidth − 16`。

注：`sampleEyedropper`（Phase 前存在）对 `getImageData` 坐标乘 density——
vp 模式下 ImageData 坐标亦为 vp，该处存在同类缺陷；不在本 Phase 修复范围，
登记为后续观察项。

## 6. 文件清单

- `note/src/main/ets/ui/editor/NoteCanvasView.ets`：常量组、状态字段、
  `zoomWindowScreenRect`/`traceRoundRect`/`renderZoomWindowOverlay`/
  `onZoomWindowTouch`/`endZoomWindowDrag`、onCanvasTouch ZOOM 路由、
  renderFrame 尾部覆盖层调用、initZoomSourceRect 重绘、
  面板 onDisAppear 收尾、vp2px 四处修复。
- `note/src/main/ets/ui/editor/NoteZoomView.ets`：advancePx/tabW/tabH 修复。
