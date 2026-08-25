# ADR-0416: 原版 EXIF 水平镜像方向集裁决

日期：2026-08-26

## 状态

Accepted

## 背景

Android 原版共享解码器 `g3.java` 在 JPEG/WebP/HEIC/HEIF 读取 `Orientation`
后，将数值 2、4、5、7 统一映射为水平镜像标志；绘制矩阵先执行
`postScale(-1, 1)`，再按方向执行四分之一旋转。Harmony 显示链此前只把
字符串 `'2'` 视为镜像，方向 4、5、7 会丢失镜像。

本地 SDK 的 `PropertyKey.ORIENTATION` 除数字外还可能返回文本方向标签，
因此判定必须先 trim/lowercase，再做数字集合比较。

## 决策

1. 新增共享纯函数 `originalExifMirrorsHorizontally()`，只对规范化后的
   `'2'`、`'4'`、`'5'`、`'7'` 返回 true。
2. `ImageAssetLoader.mirroredHorizontally` 改由该函数推导，消除内联
   不完整集合。
3. 四分之一旋转保持既有映射：3/4 为 180 度、5/8 为 270 度、6/7 为 90 度，
   其余为 0 度。
4. 渲染顺序保持编码裁剪、原版方向与镜像、用户翻转、最终绘制；本裁决不改
   持久化字节。

## 结果

显示解码与 Android 原版共享矩阵语义一致：2、4、5、7 都保留水平镜像；
非镜像方向和未知/缺失元数据继续不镜像。专项 Replay 与 ArkTS fixture 锁定
原版硬证据、共享助手、loader 接线、渲染顺序和非镜像负例。
