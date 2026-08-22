# ADR-0263：原版缩略图共享显示方向契约

- 状态：Accepted（Phase 285，2026-08-23）
- 范围：图片资产 loader 元数据 → 页面渲染 / 库页缩略图
- 相关：ADR-0258（原子插入）、ADR-0259（大图规范化）、ADR-0262（显示方向）

## 决策

库页 `ThumbnailRenderer` 不再使用默认方向调用 `ImageCanvasRenderer.renderImage()`。它必须把
`ImageAssetLoader` 返回的 `orientationDegrees` 与 `mirroredHorizontally` 传给与编辑画布相同的
image renderer。这样 EXIF 90/270 图片在缩略图中交换 oriented 尺寸，EXIF 2 水平镜像也保持一致。

该修复只补齐 Phase 284 已建立契约的遗漏接线，不改变持久化 intrinsic dimensions、AssetHash、
CREATE_BLOCK、cropRect 或资产文件。

## 原版对齐

Android `g3.java` case 6 是共享显示解码回调：

1. MIME 为 JPEG/WebP/HEIC/HEIF 时读取 EXIF Orientation；
2. orientation 2/4/5/7 触发水平镜像；
3. rotation 来自 `w34.l()`，围绕 bitmap 中点变换；
4. 90/270 创建交换物理宽高的新 Bitmap。

`nx0.java` 调用 `new g3(this, 6)`，证明该逻辑由异步图片加载工厂复用；原版没有让缩略图退回
未方向化解码路径。Harmony 以 loader 显式元数据加共享 renderer 复现该行为。

## 明确边界

- 只处理 quarter-turn rotation 和 EXIF 2 的水平镜像折叠语义；
- 真实 JPEG/WebP/HEIC/HEIF 样本、色彩空间和像素精度仍需设备验证；
- oriented-crop、翻转、Undo 后重绘的完整组合矩阵仍开放；
- `T-042` 继续保留为整个 Goal 最后一项。
