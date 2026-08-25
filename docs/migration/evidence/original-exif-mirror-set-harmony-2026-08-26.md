# Harmony 证据 — 原版 EXIF 水平镜像方向集

- 原版证据：
  `C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage\g3.java`
- 原版事实：JPEG/WebP/HEIC/HEIF 解码读取 `w34.c(1, "Orientation")` 后构造
  `iC == 2 || iC == 7 || iC == 4 || iC == 5` 的镜像标志；随后在中心点先
  `postScale(-1.0f, 1.0f)`，再 `postRotate(i7)`。
- 本地 SDK：
  `C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\ets\api\@ohos.multimedia.image.d.ts`
- SDK 事实：`PropertyKey.ORIENTATION` 声明支持数字及 `Top-right` 等文本标签；
  因此生产判定必须规范化空白和大小写后再匹配。
- 原缺口：`ImageAssetLoader` 只判断 `orientation === '2'`；方向 4、5、7 的
  位图会丢失原版水平镜像。
- 修复：新增 `OriginalImageNormalizer.originalExifMirrorsHorizontally()`，
  loader 改用该助手；旋转度数、大图缩放、裁剪和用户翻转边界不变。
- 相邻边界：持久化 normalization 不因显示链改动重写字节；GIF fail-closed、
  尺寸/文件长度校验、PixelMap 释放与 renderer 有效角度门禁保留。
- 结论：静态桌面回放锁定原版矩阵顺序与完整镜像集合；真实设备像素验收仍开放。
