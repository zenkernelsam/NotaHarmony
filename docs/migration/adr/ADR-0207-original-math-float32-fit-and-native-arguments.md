# ADR-0207：原版 Math 框适配与 Native 参数必须保持 Float32 语义

## 状态

Accepted，2026-08-15。

## 问题

Harmony 已恢复 `s18.d()` 的 floor/max/min/floor/ceil 结构，但 ArkTS `number` 和 N-API `double` 让实际运算仍以
64 位浮点执行。原版的框宽高、测量结果、比例、字号、bitmap scale 以及 `nativeMeasure/nativeDraw` 参数全部是 Java/Kotlin
`float`。算法结构相同并不代表边界结果相同。

该偏差会直接形成用户可见失败。例如框 `27×55`、native 测量 `126×319` 时：

- double 模型把 `319 * (55 / 319)` 算为略大于 55，`ceil` 得到 56；
- 旧 Harmony 又要求 fitted height 不得超过 55，因此返回 `null`；
- 原版 Float32 先舍入除法和乘法，结果恰为 55，公式应正常插入或通过编辑门禁。

反向边界同样存在：框 `240×81`、测量 `852×133` 时，原版 Float32 会得到 fitted width 241。原版直接把该
`q18/SizeF` 结果用于插入，不会因为名义最大宽度 240 而否决；旧 Harmony 的额外上限门不符合这一行为。

Native 入口也在读取 double 后才零散窄化：parse font 虽转为 float，bitmap 尺寸、居中比较/减法与 Canvas scale 仍可能
使用 double，无法复现原版 JNI `float` 参数的统一语义。

## 原版证据

- `GLMathNative.nativeMeasure(String, float, float)` 与
  `nativeDraw(String, float, float, float, int, MathDrawTarget)` 的所有几何/字号参数均为 Java float。
- `s18.d()` 的 `f/f2/fFloor/fFloor2/fMax/f3/f4/fMin` 均为 float；除法和乘法先按 Float32 舍入，再进入
  `Math.floor/Math.ceil`。
- `p18` 的 block width、height 与 density scale 字段均为 float，bitmap 尺寸来自 float 乘法后的 `Math.ceil`。
- 原版 arm64 `nativeMeasure @ 0x221990` 从 `s` 浮点寄存器保存 width/font size，并用 `fcvtzs` 对 Float32 width
  截断；`nativeDraw @ 0x221bc8` 同样以 Float32 完成宽高比较、差值、居中和 parse 参数转发。
- `vc case 27` 把 `s18.d()` 返回的 `q18.b/q18.c` 直接构造成 `SizeF`；`g18` 随后直接用该 SizeF 创建 Math block，
  没有再次执行 `<=240/<=120` 门禁。

## 决策

1. `originalMathMeasurementFontSize()` 先用 `Math.fround()` 把 box width/height 恢复为原版 Float32 输入，再执行 floor/max。
2. `fitOriginalMathMeasuredSizeToBox()` 对 measured width/height、两轴除法、min 比例以及字号/宽高乘法逐步使用
   `Math.fround()`；不得只在最终结果处一次性舍入。
3. 保留现有非有限、非正和最终零字号 fail-closed 门，避免把原版极端病态输入扩散到 native parser。
4. fitted width/height 允许最多超过 floor 后框尺寸 1px。这是 Float32 乘积经过 ceil 的可证明舍入边界；超过 1px 仍拒绝。
5. Math 插入 draft 同样允许原版最大框 `240×120` 各自最多 1px 的 Float32 ceil overshoot，任意更大结果仍拒绝。
6. Native 新增 `ReadPositiveFloat()`：先验证有限、正数与安全上限，再窄化为 float，并再次验证窄化结果有限且为正。
7. Measure 的 width/font size 与 Render 的 width/height/font size/pixelScale 从入口开始就存为 float。
8. bitmap `ceil(width * pixelScale)`、parse width/font、居中比较/差值以及 `CanvasScale` 全部使用同一组 Float32 值。
9. replay 与 ArkTS fixture 必须同时覆盖“double 会误超框而 Float32 恰好贴边”以及“原版 Float32 合法超出 1px”两类边界。

## 结果

- 精确贴合某一轴的公式不再因为 JavaScript double 尾差被误判为超框并返回 `null`。
- 原版可能出现的单像素 fitted 尺寸舍入被忠实保留，插入 geometry 与 Notability 1.0.3 更接近。
- Measure、Render、bitmap 分配、内容居中和 Canvas scale 不再混用 Float32/Float64 契约。
- 安全上限与病态输入门仍在，恢复原版数值语义不等于取消 native 分配保护。

## 边界

- 允许 1px overshoot 是原版 float+ceil 的真实结果，不应再把 `240×120` 理解为所有情况下绝对不可超过的硬裁剪框。
- 不同编译器/设备的字体测量仍可能给出不同整数 width/height；本决策保证同一测量输入后的适配算术与原版一致。
- `Math.fround()` 固定 IEEE-754 binary32 数值语义，但真实字体像素、hinting 与最终 raster 仍需真机截图对照。
