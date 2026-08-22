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

`ImageCanvasRenderer.renderImage()` 接收这两项数据。几何层只接受四个 quarter-turn 值；90/270 时以 bitmap
物理宽高交换后的 oriented 尺寸为中心，先平移到中心、旋转、必要时水平镜像，再回移并绘制。这样不修改已持久化
的 CREATE_BLOCK intrinsic dimensions，也不重复写入资产文件。

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
