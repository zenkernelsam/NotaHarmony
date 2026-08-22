# 原版缩略图共享显示方向证据（2026-08-23）

## 读取范围

- `C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage\g3.java`
- `C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage\nx0.java`

只读 Desktop 逆向产物；未在该目录写入或启动任何运行态。

## 硬证据

1. `g3.java` case 6 在 MIME 为 `image/jpeg`、`image/webp`、`image/heic`、`image/heif` 时构造
   `w34` 并调用 `w34.c(1, "Orientation")`。
2. orientation `2/4/5/7` 折叠为水平镜像；rotation 来自 `w34.l()`。
3. Matrix 先 `postScale(-1, 1, width, height)`，再 `postRotate(i7, width, height)`，随后绘制到
   新 Bitmap；90/270 的物理宽高交换。
4. `nx0.a()` 调用 `new g3(this, 6)`，说明共享解码回调由异步加载工厂复用。原版没有在库页/缩略图侧
   单独退回无方向显示。

## Harmony 差距与修复

Phase 284 后编辑画布已传入 loader 方向元数据，但 `ThumbnailRenderer` 的图片分支仍使用 renderer 默认值
`(0,false)`。Phase 285 将同一 `LoadedImageAsset.orientationDegrees/mirroredHorizontally` 传给同一个
`ImageCanvasRenderer.renderImage()`，避免页面正确而缩略图方向错误。
