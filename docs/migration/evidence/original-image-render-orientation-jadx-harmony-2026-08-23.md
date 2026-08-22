# Phase 284 图片显示方向逆向与 Harmony 证据（2026-08-23）

来源：Desktop 只读反编译源、本地 DevEco SDK 与正式仓源码。本文件只记录方向适配相关证据。

## 原版插入规范化

`vuh.java`：

- header/ORIENTATION 解析后，90/270 先交换对外宽高；
- 超 3000px 时按 encoded 轴计算 sample size；
- `Bitmap.createScaledBitmap(...)` 后 `matrix.postRotate(iL)`；
- 最终以 `WEBP_LOSSY, 85` 写回并返回 `image/webp`。

因此规范化成功后的资产通常已携带像素旋转。Phase 281 已实现该路径。

## 原版显示解码

`g3.java` case 6：

- MIME 为 `image/jpeg`、`image/webp`、`image/heic` 或 `image/heif` 时创建 `w34`；
- `w34.c(1, "Orientation")` 得到 EXIF orientation；
- `p34.a` 在 orientation `2/7/4/5` 时为 true，表示水平镜像；
- `w34.l()` 返回 rotation degrees；
- 变换中点为 `(bitmap.width / 2, bitmap.height / 2)`；
- `matrix.postScale(-1, 1, width, height)` 处理镜像；
- `matrix.postRotate(rotation, width, height)` 处理 rotation；
- map rect 后平移负偏移；
- rotation 90/270 创建物理宽高交换的新 Bitmap，再用 Canvas 绘制变换后的原图。

这证明原版显示层不依赖“所有平台自动应用 EXIF”，而是显式把 mirror + rotation 应用到 bitmap。

## Harmony 现状与适配

`ImageAssetLoader.ets` 原先只用 header 尺寸做 desiredSize 缩放，未读取 ORIENTATION；小尺寸带 EXIF 图片会以
encoded 方向进入 renderer。

Phase 284：

1. 导出 `originalRotationDegrees()`；
2. loader 读取 `image.PropertyKey.ORIENTATION`，默认 `'1'`；
3. 用既有 `originalImageOrientedDimensions()` 验证 oriented 尺寸合法；
4. `LoadedImageAsset` 增加 `orientationDegrees` 与 `mirroredHorizontally`；
5. canvas 把两项元数据传给 `ImageCanvasRenderer.renderImage()`；
6. renderer 只接受 `0/90/180/270`，在 oriented 中心执行 rotate + mirror 后绘制。

## 明确证据边界

- 本地 SDK 未证明 `createPixelMap()` 会统一应用全部 EXIF orientation/mirror 组合；
- 因此 Harmony 采用显式元数据传递，而不是声明 ImageKit 自动等价 Android；
- 未运行设备样本，JPEG/WebP/HEIC/HEIF 的实际解码行为仍开放；
- cropRect 与 oriented-crop 全矩阵未在本阶段声称闭环。
