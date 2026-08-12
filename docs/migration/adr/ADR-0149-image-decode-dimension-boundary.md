# ADR-0149: ImageAssetLoader 尺寸边界

## 决策

`ImageAssetLoader` 从 `ImageInfo` 读取宽高后，要求二者都是正的安全整数；否则返回 `FAILED`，不计算缩放尺寸也不构造位图。

## 原因

底层图片元数据异常时，NaN、无穷、零或非整数尺寸会传播到 `desiredSize` 和 ImageBitmap，导致渲染错误或资源分配风险。正常图片行为不变。

## 验收

静态 replay 检查尺寸校验位于缩放计算之前；真实损坏图片和超大图片仍需运行态验收。
