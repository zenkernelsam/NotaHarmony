# ADR-0194：原版 Math 必须按块框自适应字号且编辑只改 LaTeX

## 状态

Accepted，2026-08-14。

## 问题

Phase 149 接入真实 MicroTeX 后，Harmony 的公式绘制仍固定传入 20px 字号。`MathCanvasRenderer` 虽然创建了
与 Math block 等大的位图，但公式内容并不会自动放大到块框；小公式插入后明显偏小，较复杂公式也可能在固定
字号和宽度约束下产生与原版不同的占框、换行或裁切。

插入路径同样先以固定 20px 测量，再只允许向下缩放到 `240x120`。原版会把小公式放大到最大框的限制轴，
旧移植因此系统性生成过小的 Math block。

编辑路径还有更直接的功能故障：它在修改 LaTeX 后重算 `blockWidth/blockHeight/bounds`，但
`classifyOriginalMathLatexMutation()` 按原版 type-23 field 10 协议只允许 LaTeX register 变化。除非重算尺寸
碰巧与旧尺寸完全相同，否则提交会被判定为“changes unsupported fields”，用户看到编辑失败，公式无法保存。

## 原版证据

- `decompiled_1.0.3/sources/defpackage/s18.java` 的 `d(width, height, latex)`：
  - 对宽高分别 `floor`；
  - 以两者最大值作为首次 `nativeMeasure()` 的 font size；
  - 用 `min(width/measuredWidth, height/measuredHeight)` 等比适配；
  - 最终 font size 取 `floor`，输出宽高均取 `ceil`。
- `decompiled_1.0.3/sources/defpackage/p18.java`：位图仍按完整 block 宽高创建，但
  `nativeDraw()` 使用 `s18.d()` 返回的拟合字号，而不是固定字号。
- `decompiled_1.0.3/sources/defpackage/g18.java` 的插入路径：以固定最大框 `240x120` 调用 `s18.d()`，再把返回的
  fitted width/height 写入新 Math block。
- 同文件编辑路径 `g18.i()` 只构造 LaTeX nullable setter 并提交；没有重新测量或修改 block geometry。
- `decompiled_1.0.3/sources/defpackage/w18.java` 对公式位图的缓存键包含 LaTeX、尺寸、颜色等输入；先测量、后绘制
  是原版 renderer 的正常两阶段路径。

## 决策

1. 在 `OriginalMathInsertPlan` 增加可独立测试的原版框适配算法：
   - `originalMathMeasurementFontSize()` 返回 `max(floor(width), floor(height))`；
   - `fitOriginalMathMeasuredSizeToBox()` 按原版比例计算 fitted font/width/height；
   - 拒绝非有限值、非正框、无效测量、非正比例和最终为零的字号。
2. `OriginalMathEngine.fit()` 先使用原版初始字号调用 native measure，再把结果交给纯适配算法。
3. `OriginalMathEngine.render()` 不再接收任意外部字号；它先执行 `fit()`，再把 fitted font size 交给
   `renderNative()`。位图尺寸、颜色、像素倍率和缓存预算保持不变。
4. `MathCanvasRenderer` 删除固定 `DEFAULT_MATH_FONT_SIZE = 20`，所有主画布与缩略图公式统一走原版框适配。
5. Math 插入先对原版 `240x120` 最大框执行 `fit()`，再用返回宽高居中创建 block；允许小公式像原版一样放大，
   也允许宽公式等比缩小。
6. Math 编辑仍通过 `fit()` 做语法和可绘制性门禁，但 durable snapshot 只修改 `latex`；保留原 block 宽高、
   transform 和 bounds，与 `g18.i()` 及 type-23 field 10 协议一致。
7. 保留现有 latex-only classifier、事务、Undo/Redo 和 upload-immediate 出站协议；本阶段不扩张 type-23 的字段
   所有权。

## 结果

- 公式会在既有 block 内按原版比例选择字号，不再固定为 20px 并缩在左上区域。
- 新插入的小公式会填满 `240x120` 的限制轴，宽公式和高公式保持等比。
- 编辑公式不再因附带几何变化而被 latex-only 持久化门禁拒绝。
- 编辑前后 block 的位置、尺寸、变换和选区边界保持稳定，新的 LaTeX 在同一框内重新适配。
- 主画布与缩略图继续共享同一公式引擎与缓存身份。

## 边界

- 桌面 replay 验证了原版算法结构、字段所有权和确定性数值模型；真实字体像素、复杂 LaTeX、换行、裁切、
  baseline 和不同设备 density 仍需设备截图与原版逐样本比较。
- 当前 native adapter 使用 MicroTeX 同源实现，不代表所有 Android `libglmath.so` 字体选择和绘图细节已经像素级
  等价；本决策关闭的是框适配与编辑字段语义，不虚报关闭全部视觉差异。
- 公式 block 的外部 transform 仍由现有统一选区几何负责；本阶段没有改变缩放、旋转或持久历史协议。
