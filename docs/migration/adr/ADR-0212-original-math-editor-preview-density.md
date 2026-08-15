# ADR-0212：Math 编辑器预览必须先按 Density 转为物理像素

## 状态

Accepted，2026-08-15。本文修正 ADR-0211 初版把“280×96、1×”误解为 raw bitmap 像素的结论。

## 问题

Phase 234 恢复了 Math 编辑器四态和 Native preview，但直接把 280、96 作为 bitmap 像素宽高，并保留
`pixelScale=1`。ArkUI 的 preview 布局尺寸是 vp；在 2×/3× 密度设备上，280×96 像素会被拉伸到
560×192 / 840×288 物理像素，导致公式模糊、细线和文字边缘偏离原版。

单纯把 `pixelScale` 改成 Density 也不是严格复刻：原版先用 Density 改变传给 measure/fit 的框宽高，之后才把
独立 scale 传给 bitmap 创建与 Canvas。两种运算顺序在字号、ceil 取整和平台 hinting 边界上可能不同。

## 原版依据

- `v08` 的 preview layout 使用 280dp 宽、96dp 高。
- `axi.a()` 从 CompositionLocal 取得 `r93` Density，并执行 `j0(280.0f)`、`j0(96.0f)`。
- `r93.j0(float f)` 返回 `a() * f`，其中 `a()` 是当前 density。
- `w08` 把这两个已经转换的 float 传给 `p18`，同时明确传入独立 `scale=1.0f`。
- `p18` 先以 `ceil(width * scale)` / `ceil(height * scale)` 创建 bitmap，再 `canvas.scale(scale, scale)`；
  因此编辑器 bitmap 在 3× density 下应接近 840×288 像素，而不是 280×96 像素。

## 决策

1. ArkUI 布局和 overlay preview 区继续使用 280vp×96vp，不改变用户可见尺寸。
2. 调用 `OriginalMathEngine.render()` 前分别使用 `vp2px(280)` 与 `vp2px(96)` 获取当前窗口的物理像素框。
3. render 的 `pixelScale` 继续保持原版 1；不得同时对框尺寸和 pixelScale 应用 Density。
4. Density 转换结果若非有限或非正，编辑器 fail closed 为 Invalid，不进入 Native 分配。
5. replay 同时锁定 `axi/r93/p18` 的转换顺序、Harmony `vp2px` 接线及 1×/2×/3× 数值模型。

## 结果

- 高密度屏不再把低分辨率 280×96 bitmap 放大显示。
- Native measure、fit、ceil 和 draw 接收与原版同顺序形成的物理框，预览细线、文字与透明边缘更清晰。
- overlay 的逻辑尺寸、四态、主题颜色、异步 generation 和资源释放语义保持不变。

## 边界

- 真机仍需比较 1×/2×/3× density 下的实际 bitmap 尺寸、字体 hinting 与右/下边缘裁切。
- 多显示器或运行中 Density 改变是否触发 ArkUI area/configuration 回调需要设备验证；每次 draft、主题或重新打开
  overlay 都会读取当时的最新 Density。
- 本阶段不启动设备、模拟器、虚拟机或 Hypium。
