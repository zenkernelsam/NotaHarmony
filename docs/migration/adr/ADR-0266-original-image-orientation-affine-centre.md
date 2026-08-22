# ADR-0266：原版图片方向仿射的 encoded 中心

- 状态：Accepted（Phase 288，2026-08-23）
- 范围：EXIF mirror + rotation → Canvas2D transform → crop / user flip
- 相关：ADR-0262（显示方向）、ADR-0263（缩略图共享方向）、ADR-0264（组合顺序）

## 决策

`ImageCanvasRenderer` 的 baked orientation 变换必须以 encoded bitmap 的物理中心
`bitmap.width / 2, bitmap.height / 2` 为中心，而不是交换后的 `orientedWidth/orientedHeight`。这精确复现
Android Matrix 的构造顺序和 pivot；oriented dimensions 只用于描述输出尺寸，不参与 pivot。

## 原版证据

`g3.java` case 6 固定：

```java
float width = bitmapDecodeStream.getWidth() / 2.0f;
float height = bitmapDecodeStream.getHeight() / 2.0f;
matrix.postScale(-1.0f, 1.0f, width, height);
matrix.postRotate(i7, width, height);
```

90/270 只决定新 Bitmap 使用 `height x width`，Matrix pivot 仍是原 Bitmap 宽高。

## 明确边界

- 本阶段只修正 pivot 数值；encoded crop → baked orientation → user flip 的顺序不变；
- 真实设备 EXIF 样本、色彩空间、像素精度与性能仍开放；
- `T-042` 继续保留为整个 Goal 最后一项。
