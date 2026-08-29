# ADR-0264：原版图片用户翻转与 EXIF 方向组合顺序

- 状态：Accepted（Phase 286，2026-08-23）
- 范围：encoded crop → baked display orientation → user flip → draw
- 相关：ADR-0259（大图规范化）、ADR-0262（显示方向）、ADR-0263（缩略图共享方向）

## 决策

`ImageCanvasRenderer.renderImage()` 将 raw encoded bitmap 通过 loader 提供的
`orientationDegrees/mirroredHorizontally` 映射到 oriented intrinsic 域；随后应用
`imageFlippedHorizontally/Vertically` 与 oriented crop/fit。cropRect 与翻转标记属于同一
oriented intrinsic metadata 坐标系，EXIF 方向只负责 source bitmap 的坐标桥接。

该顺序不修改持久化数据，也不把用户翻转折叠进 EXIF mirror；同一资产可被不同 IMAGE block 以不同的用户
翻转状态复用。

## 原版对齐

Android 共享显示解码 `g3.java` case 6 先构造 Matrix：

1. orientation 2/4/5/7 执行 `postScale(-1, 1)`；
2. 再执行 `postRotate(w34.l())`；
3. map rect 后平移回原点并绘制到 oriented Bitmap；
4. `b40` 以 oriented bitmap 与 `dp5.size` 解释 cropRect，再应用 block flip。

调用方随后得到的是已经烘焙方向和 EXIF mirror 的 oriented pixels。用户层 flip 属于 block 状态，作用于该
oriented result 之后。Harmony 通过显式 renderer 顺序复现这一契约。

## 明确边界

- 本阶段统一 quarter-turn rotation、EXIF horizontal mirror、图像域 crop 和用户 H/V flip 的顺序；
- 不承诺真实设备 JPEG/WebP/HEIC/HEIF 样本、色彩像素和全部 EXIF 变体验收；
- oriented-crop 编辑 UI 的完整矩阵仍开放；
- `T-042` 继续保留为整个 Goal 最后一项。

## Phase 529 坐标契约澄清（2026-08-29）

原版 `g3` 返回已方向化的 bitmap，`b40` 以 oriented `dp5.size` 将 `cropRect` 映射到该
bitmap；因此 crop 与 intrinsic 应属于 oriented 域，而不是 raw encoded 域。Phase 529
将 Harmony 的渲染顺序具体化为：

```text
raw encoded bitmap --EXIF affine--> oriented bitmap domain
                         --user flip--> oriented crop/fit --> block transform
```

renderer 的 `orientationTransform` 使用 encoded bitmap 宽高和正边界平移；持久化 cropRect、
翻转寄存器和 IMAGE intrinsic 均保持 oriented 轴。旧版文档中“encoded crop”表述由本澄清
取代，历史 type-23/字段布局不变。
