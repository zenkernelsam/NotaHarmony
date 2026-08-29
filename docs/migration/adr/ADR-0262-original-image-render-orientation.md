# ADR-0262：原版图片显示方向适配

- 状态：Accepted（Phase 284，2026-08-23）
- 范围：本地图片资产 decode → EXIF orientation / mirror 元数据 → canvas 渲染变换
- 相关：ADR-0258（原子插入）、ADR-0259（大图规范化）、ADR-0261（生产 caller）

## 决策

`ImageAssetLoader` 在读取资产时保留两项渲染元数据：

```text
orientationDegrees: 0 | 90 | 180 | 270
mirroredHorizontally: boolean
```

`ImageCanvasRenderer.renderImage()` 接收这两项数据。几何层只接受四个 quarter-turn 值；方向矩阵以 raw bitmap
物理宽高为输入并平移到 oriented 正边界，再在 oriented intrinsic 域完成 crop/fit。这样不修改已持久化的
CREATE_BLOCK intrinsic dimensions，也不重复写入资产文件。

## 原版对齐与平台差距

1. 插入规范化：Android `vuh.b()` 对超 3000px 图片用 `Matrix.postRotate(iL)` 后重写 WebP；Phase 281 已复现，
   本阶段不改该路径。
2. 显示解码：Android `g3.java` case 6 对 `image/jpeg`、`image/webp`、`image/heic`、`image/heif` 读取
   `w34.c(1, "Orientation")` 与 `w34.l()`；orientation 2/4/5/7 触发水平镜像，`w34.l()` 提供 rotation。
3. 原版显示变换在 bitmap 宽高的中点执行：
   - `postScale(-1, 1, width / 2, height / 2)`；
   - `postRotate(degrees, width / 2, height / 2)`；
   - map rect 后平移负偏移；
   - 90/270 创建交换宽高的新 Bitmap 并绘制。
4. Harmony 当前 ImageKit loader 不等价暴露 Android 的完整 orientation-aware decode contract，因此把
   orientation/mirror 作为显式 loader 结果传给 renderer，而不是伪造 ImageKit 行为。

## 明确边界

- 只处理 quarter-turn rotation 和 EXIF 2 水平镜像；EXIF 4/5/7 的组合语义按原版规则折叠为 mirror + rotation。
- cropRect 仍使用 encoded bitmap 坐标；当前实现不声称支持任意 oriented-crop 组合的完整矩阵。
- 色彩空间、premultiplied alpha、RGB565 降级和设备像素验收不在本阶段关闭。
- 真实 JPEG/WebP/HEIC/HEIF 样本、缩略图、裁剪、Undo 后重绘需要设备验证。
- `T-042` 继续保留为整个 Goal 最后一项。

## Phase 529 坐标契约澄清（2026-08-29）

原版 `g3` 已将 raw encoded bitmap 烘焙为 oriented bitmap 后交给 `b40`；`dp5.size` 与
`hp5.cropRect` 因而共享 oriented 图像域。上面的“encoded crop”描述仅适用于 Phase 284
当时仍采用 encoded intrinsic 的临时 Harmony 适配，现由 Phase 529 supersede。

当前契约为：`ImageElement.intrinsicWidth/Height` 与 `cropRect` 使用 oriented intrinsic
坐标；Harmony loader 仍可返回 raw encoded `ImageBitmap`，但 `ImageCanvasRenderer` 先用
encoded 物理宽高构造带正边界平移的 EXIF 仿射矩阵，再在 oriented 域执行用户翻转、crop
与 block fit。这样不依赖 ImageKit 是否自动应用 EXIF，也与原版 `g3 → b40` 的尺寸关系一致。
