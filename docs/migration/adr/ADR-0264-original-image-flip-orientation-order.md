# ADR-0264：原版图片用户翻转与 EXIF 方向组合顺序

- 状态：Accepted（Phase 286，2026-08-23）
- 范围：encoded crop → baked display orientation → user flip → draw
- 相关：ADR-0259（大图规范化）、ADR-0262（显示方向）、ADR-0263（缩略图共享方向）

## 决策

`ImageCanvasRenderer.renderImage()` 在裁剪 encoded bitmap 像素之后，才应用 loader 提供的
`orientationDegrees/mirroredHorizontally`；最后再应用 `imageFlippedHorizontally/Vertically`。
因此 cropRect 与翻转标记继续保持在 encoded bitmap / intrinsic metadata 坐标系中，而 EXIF 方向只作为
display decode 的 baked transform。

该顺序不修改持久化数据，也不把用户翻转折叠进 EXIF mirror；同一资产可被不同 IMAGE block 以不同的用户
翻转状态复用。

## 原版对齐

Android 共享显示解码 `g3.java` case 6 先构造 Matrix：

1. orientation 2/4/5/7 执行 `postScale(-1, 1)`；
2. 再执行 `postRotate(w34.l())`；
3. map rect 后平移回原点并绘制到 oriented Bitmap。

调用方随后得到的是已经烘焙方向和 EXIF mirror 的 oriented pixels。用户层 flip 属于 block 状态，作用于该
oriented result 之后。Harmony 通过显式 renderer 顺序复现这一契约。

## 明确边界

- 本阶段统一 quarter-turn rotation、EXIF horizontal mirror、encoded crop 和用户 H/V flip 的顺序；
- 不承诺真实设备 JPEG/WebP/HEIC/HEIF 样本、色彩像素和全部 EXIF 变体验收；
- oriented-crop 编辑 UI 的完整矩阵仍开放；
- `T-042` 继续保留为整个 Goal 最后一项。
