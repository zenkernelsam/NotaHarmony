# ADR-0198：Native Math 必须恢复原版四字段度量与框内居中

## 状态

Accepted，2026-08-14。

## 问题

Harmony 的 GLMath 适配层已经能够解析和绘制公式，但 `nativeMeasure/nativeDraw` 与 Notability 1.0.3 的
native 协议仍有四处会直接改变布局和像素位置的偏差：

- 传给 `LaTeX::parse()` 的宽度使用 `ceil(width)`，原版使用向零截断；
- 行间距固定为 `4.0f`，原版传入 `0.0f`；
- 测量高度返回 `getHeight() + getDepth()`，而原版分别返回 `getHeight()` 与 `getDepth()`；由于当前
  MicroTeX 的 `getHeight()` 已包含公式总高，这等于把 baseline 以下的 depth 重复计算一次；
- 绘制固定从 `(0, 0)` 开始，原版会把小于 block 的公式按整数偏移居中。

结果是公式拟合字号偏小、窄宽度换行边界和原版不同，并且较小公式贴在 block 左上角而不是位于中央。

## 原版证据

- `decompiled_1.0.3/sources/defpackage/n18.java` 的 `MathMetrics` 明确包含
  `widthPx`、`heightPx`、`baselineFraction`、`depthPx` 四个字段。
- `s18.e()` 要求 native 数组至少有四项，并按 `[0] width`、`[1] height`、`[2] baseline`、
  `[3] depth` 构造 `n18`；`s18.d()` 只使用前两项进行框内拟合。
- `p18.invoke()` 对外层 bitmap 宽高使用 `ceil(block * pixelScale)`，但仍把逻辑 block 宽高原样传入
  `nativeDraw()`。
- 原版 arm64 `libglmath.so` 的 `nativeMeasure`（`0x221990`）在进入 parse 前使用 `fcvtzs` 转换宽度，
  并向 `LaTeX::parse()` 传入 `0.0f` 行间距；返回顺序为
  `getWidth(), getHeight(), getBaseline(), getDepth()`。
- 同一 so 的 `nativeDraw`（`0x221bc8`）分别计算
  `int(blockWidth - renderWidth) / 2` 与 `int(blockHeight - renderHeight) / 2`；仅当 render 小于 block
  时使用偏移，否则使用 0，然后调用 `render->draw(graphics, x, y)`。

## 决策

1. `LaTeX::parse()` 的 line spacing 固定为原版 `0.0f`。
2. 测量和绘制传给 parser 的逻辑宽度都使用 `static_cast<int>(width)`；不得对 parse width 做 `ceil`。
3. 外层 bitmap 的像素宽高继续使用 `ceil(logicalSize * pixelScale)`，保持 `p18` 的分配规则。
4. `MathMeasureResult` 暴露四个原版槽位：
   - `width = getWidth()`；
   - `height = getHeight()`；
   - `baseline = getBaseline()`；
   - `depth = getDepth()`。
5. `OriginalMathEngine.fit()` 仍只消费 width 与 height；depth 不能再次并入 height。
6. 绘制前读取 render width/height，并完全复刻原版整数居中：差值先截断，再做整数除以 2。
7. render 不小于 block 时偏移必须为 0，禁止为了“居中”产生负坐标。
8. 居中计算必须位于 native drawing 资源校验之后，并继续由既有异常与 RAII 回收边界保护。

## 结果

- 公式拟合不再把 depth 重复计入总高，因此不再系统性选取偏小字号。
- 小公式会在完整 block bitmap 内水平、垂直居中，恢复原版留白分配。
- 分数宽度的 parse 边界、自动换行及多行公式间距更接近原版 native。
- baseline fraction 与 depth 重新可供后续详细度量消费者独立使用。
- bitmap 像素尺寸、pixelScale、安全预算及失败回收行为保持不变。

## 边界

- 桌面 replay 锁定控制流、字段协议和整数模型；不同平台字体栅格化造成的最终像素差异仍需真机截图确认。
- 当公式本身大于 block 时，原版也从 `(0, 0)` 开始绘制；本阶段不额外缩放或使用负偏移。
- `getHeight()` 与 `getDepth()` 的具体数值由原版同源 MicroTeX box 模型决定；不得仅凭字段名再次相加。
