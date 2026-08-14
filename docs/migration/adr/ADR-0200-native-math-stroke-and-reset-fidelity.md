# ADR-0200：Native Math 必须恢复原版 Stroke 重放与逻辑 reset

## 状态

Accepted，2026-08-15。

## 问题

Harmony `HarmonyGraphics` 的线条与变换适配仍有三处偏离 Notability 1.0.3：

- 构造时立即把 MicroTeX 的逻辑默认 Stroke（1px、round cap、round join）写入 Pen；原版 Android
  `MathDrawTarget` 的 stroke Paint 初始保持平台默认（0px hairline、butt cap、miter join）。
- `setStrokeWidth()` 只改 Pen width；原版 native 在更新逻辑宽度后重新调用完整 `setStroke()`，因此
  cap、join 和正 miter limit 会一起重放。
- `reset()` 调用 `OH_Drawing_CanvasResetMatrix()`；原版 native 的 reset 只把内部 `sx/sy` 设回 1，
  不触碰 Android Canvas。Harmony 的实现会把 Render 入口先施加的 `pixelScale` 一并清除。

此外，Harmony 还维护从旧版 port 沿袭、但当前原版不再使用的 `tx_/ty_` 伪矩阵状态。

## 原版证据

- `MathDrawTarget` 构造函数只创建 `new Paint(1)` 并设置 `Style.STROKE`，没有设置 stroke width、cap、
  join 或 miter；Android Paint 因此保持平台默认值。
- `MathDrawTarget.setStroke()` 同时应用 width、cap、join，并仅在 miter limit 大于 0 时覆盖平台值。
- 原版 arm64 `libglmath.so`：
  - `Graphics2D_Android::setStrokeWidth @ 0x220650` 先写入逻辑 Stroke 的 width，随后通过虚表调用
    `setStroke(currentStroke)`；
  - `translate @ 0x220674` 直接转发 Canvas，不维护 tx/ty；
  - `scale @ 0x220698` 更新 sx/sy 后转发 Canvas；
  - `reset @ 0x220730` 仅把 sx/sy 两个 float 写回 1，不调用 Java Canvas。
- MicroTeX `LineBox::draw()` 使用 `setStrokeWidth(thickness)`，完成后再恢复旧宽度，因此是否重放完整
  Stroke 会直接影响线端、连接和 miter 行为。
- `TeXRender::draw()` 在整棵 box 绘制完成后才调用 `g2.reset()`；Render 在此之前已在 Canvas 上施加
  `pixelScale`。

## 决策

1. HarmonyGraphics 构造时显式建立 Android stroke Paint 对应的平台默认：width 0、flat/butt cap、
   miter join；不调用 `setStroke(tex::Stroke())`。
2. `stroke_` 仍以 MicroTeX 的 `Stroke()` 作为逻辑状态，平台初始状态与逻辑状态必须分开。
3. `setStrokeWidth(width)` 更新 `stroke_.lineWidth` 后调用 `setStroke(stroke_)`，完整重放当前
   width/cap/join/miter。
4. miter limit 为 0 时继续不覆盖平台当前值，保持原版 positive-only 语义。
5. `translate()` 只转发 Native Canvas；删除不参与原版当前实现的 tx/ty 状态。
6. `reset()` 只恢复逻辑 `sx_/sy_ = 1`，不得调用 `OH_Drawing_CanvasResetMatrix()`。
7. 外层 bitmap 的 `pixelScale` 必须在整个公式绘制生命周期保持有效。

## 结果

- LineBox、规则线和后续恢复宽度时会同步保留当前 cap/join/miter，接近原版线条端点与拐角。
- 首次绘制前的平台 Pen 状态与原版 Android Paint 默认一致，不再提前注入 MicroTeX 逻辑 Stroke。
- 公式绘制完成时的逻辑 reset 不会误清除 bitmap 的设备像素倍率。
- 删除无效 tx/ty bookkeeping，避免它与真实 Canvas matrix 产生伪一致性。

## 边界

- Android hairline 与 Harmony Native Drawing 的 0-width Pen 栅格化可能仍有平台像素差异。
- 当前 MicroTeX 只在完整 box draw 后调用 reset；本决策仍按原版保留 no-op Canvas reset，以免未来绘制
  复用时破坏外层矩阵。
- miter limit 0 不会主动恢复平台默认值，这是原版 `MathDrawTarget.setStroke()` 的既有语义。
