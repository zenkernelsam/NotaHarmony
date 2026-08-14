# ADR-0205：Native Math 像素导出必须显式处理行布局与格式

## 状态

Accepted，2026-08-15。

## 问题

Harmony Render 通过 `OH_Drawing_BitmapGetPixels()` 取得 Native Bitmap 内部地址后，直接按
`pixelWidth * pixelHeight * 4` 做一次连续 memcpy。该实现隐含三个未验证假设：

1. Native Bitmap 每行严格等于 `width * 4`，没有更大的 row bytes 或 padding；
2. Build 后实际 color/alpha format 与请求值完全相同；
3. 内部存储布局可以直接作为 ArkTS PixelMap 的紧密 RGBA_8888 输入。

Harmony Native Drawing 明确允许 pixel row size “or larger”，并提供带 `dstRowBytes` 的
`OH_Drawing_BitmapReadPixels()`。若平台内部采用更大 stride，连续前缀 memcpy 会把首行 padding 当作下一行像素，导致
后续行整体错位；格式或 alpha type 变化还可能造成错色或透明边缘异常。

## 原版与平台证据

- 原版 `p18` 创建 Android `Bitmap.Config.ARGB_8888`，随后把同一个 Bitmap 包装成 Canvas 并直接交给
  MathDrawTarget；原版没有把 Bitmap 内部裸地址重新解释为紧密行缓冲。
- Harmony SDK `OH_Drawing_BitmapCreateFromPixels` 的 rowBytes 文档明确允许“size of pixel row or larger”。
- SDK 12+ 提供 `OH_Drawing_BitmapReadPixels(bitmap, dstInfo, dstPixels, dstRowBytes, srcX, srcY)`，由平台按目标
  row bytes 导出像素并返回成功状态。
- 当前项目 compatible/target SDK 为 6.0.1(21)，可使用 Bitmap color/alpha 查询与 ReadPixels API。
- ArkTS `image.createPixelMapSync` 以紧密的 RGBA_8888 ArrayBuffer 和显式 width/height 建图，因此 native 必须交付
  无内部 padding 的目标缓冲。

## 决策

1. Build 后继续检查 backing pixels 非空与实际 width/height。
2. 同时检查实际 color format 为 `COLOR_FORMAT_RGBA_8888`，alpha format 为 `ALPHA_FORMAT_PREMUL`。
3. 目标行长度显式定义为 `rowBytes = pixelWidth * 4`。
4. ArrayBuffer 长度由 `rowBytes * pixelHeight` 计算，不引用 Native Bitmap 的未知内部跨度。
5. 建立目标 `OH_Drawing_Image_Info`，尺寸、color 与 alpha 必须与 ArkTS PixelMap 输入契约一致。
6. 用 `OH_Drawing_BitmapReadPixels()` 将 bitmap 导出到目标 ArrayBuffer，并传入紧密 rowBytes。
7. ReadPixels 返回 false 时整次 Render 失败，不构造 valid=true 结果。
8. 删除 `std::memcpy(destination, source, byteLength)`，禁止重新引入内部连续布局假设。
9. ArrayBuffer 分配与指针验证必须先于 ReadPixels；ReadPixels 成功必须先于成功结果对象构造。

## 结果

- Native Bitmap 即使使用更大内部 stride，ArkTS 收到的每一行仍严格紧密排列。
- 平台格式或 alpha type 与预期不一致时立即失败，不把错色数据送入 PixelMap。
- 像素导出本身有可检查的 boolean 结果，失败不会形成部分 ArrayBuffer 成功对象。
- 原版“绘制结果属于完整 Bitmap”的语义在 Harmony 适配中由平台 ReadPixels 安全转换，而不是裸地址猜测。
- 预乘 alpha 与 RGBA_8888 契约在 native 创建、导出和 ArkTS 消费三处保持一致。

## 边界

- ReadPixels 可处理行跨度与平台支持的格式读取，但无法证明 ArkTS PixelMap 在所有设备 GPU 后端上的最终色彩管理完全一致。
- 当前仍保留 GetPixels 非空检查作为 Bitmap backing storage 建立门；该地址不再用于像素复制。
- 真机需用非 4/8 对齐宽度、半透明彩色公式和逐行棋盘式测试图确认无错行、红蓝互换或 alpha halo。
