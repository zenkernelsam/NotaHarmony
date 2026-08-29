# ADR-0500：原版小图 EXIF 归一化边界

日期：2026-08-29

## 状态

Accepted

## 背景

Phase 281/407 已实现原版大图的旋转、缩放和 WebP lossy 85 适配，但后续复审发现
`OriginalImageNormalizer` 把 `rotationDegrees !== 0` 也作为重写条件。这样一张
oriented 宽高均不超过 3000px、但 EXIF 为 3–8 的小图，会在原版本应直接返回原始
文件的路径上被重新编码为 WebP。

## 原版证据

`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage\vuh.java`
在计算 oriented 轴后先执行：

```java
if (i3 <= 3000 && i4 <= 3000) {
    return ep5Var;
}
```

只有越过该门禁才会进入 `BitmapFactory.decodeFile`、`postRotate` 和
`WEBP_LOSSY, 85` 重编码。非零 EXIF 旋转本身不是重写理由。

## 决策

`normalizeOriginalImageBytes()` 的 `needsNormalization` 只由 oriented 宽高是否
超过 3000px 决定：

```text
!isOriginalNormalizedImageDimensions(oriented.width, oriented.height)
```

阈值内无论 EXIF 角度或镜像标记如何，都返回 stable 原始字节并保留 MIME/EXIF；
显示端继续由 `ImageAssetLoader`/`ImageCanvasRenderer` 应用方向。超过阈值时仍按
既有 encoded-axis 计划、先旋转后缩放、WebP lossy 85 和资源释放语义执行。

## 结果

小图不会被无谓重编码、丢失容器元数据或改变压缩特性；大图路径与 Android
`vuh.b()` 保持不变。专项 Replay 增加了原版立即返回顺序、Harmony stable-byte
返回顺序和 3–8 方向边界 fixture。

## 未闭环

- 真实设备 JPEG/WebP/HEIF/EXIF 解码与编码矩阵、色彩/透明度和峰值内存仍需设备验收；
- 小图方向的设备像素视觉仍不能由静态 Replay 代替；
- `T-042` 继续严格留到整个 Goal 最后一项。
