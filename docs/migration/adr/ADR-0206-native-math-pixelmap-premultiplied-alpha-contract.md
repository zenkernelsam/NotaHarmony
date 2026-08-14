# ADR-0206：Native Math PixelMap 必须显式声明预乘 Alpha

## 状态

Accepted，2026-08-15。

## 问题

Native Math 创建并导出的位图已经明确采用 `RGBA_8888 + PREMUL`：Native Bitmap 的实际 alpha format 会被验证，
`OH_Drawing_BitmapReadPixels()` 的目标 `OH_Drawing_Image_Info` 也声明为 `ALPHA_FORMAT_PREMUL`。但是 ArkTS
调用 `image.createPixelMapSync()` 时只声明了源、目标 pixel format，没有声明 `alphaType`。

`RGBA_8888` 只描述通道顺序与位宽，不描述 RGB 是否已经乘过 alpha。若预乘字节被当作非预乘输入再次转换，半透明彩色
字形边缘会被二次乘 alpha，表现为发暗、脏边或 halo。纯黑、纯白与完全不透明像素可能掩盖该问题，因此普通公式很难暴露
契约断裂。

## 原版与平台证据

- 原版 `p18` 创建 `Bitmap.Config.ARGB_8888` Bitmap，并直接在该 Bitmap 的 Canvas 上绘制 MathDrawTarget；绘制结果始终
  留在 Android Bitmap/Canvas 的 alpha 合成契约内，没有跨层重新猜测 alpha association。
- Harmony Native Bitmap 创建格式为 `COLOR_FORMAT_RGBA_8888 + ALPHA_FORMAT_PREMUL`，Build 后还会查询并验证实际
  alpha format。
- Native 像素出口使用同为 `ALPHA_FORMAT_PREMUL` 的目标 Image Info，因此传给 ArkTS 的 RGB 字节已经是预乘值。
- ArkTS PixelMap 初始化选项提供 `image.AlphaType.PREMUL`，可以让消费端明确按预乘语义解释同一缓冲。
- `PixelMapFormat.RGBA_8888` 与 `AlphaType.PREMUL` 是两个独立维度；只声明前者不足以封闭跨语言像素契约。

## 决策

1. `image.createPixelMapSync(result.pixels, options)` 必须显式设置
   `alphaType: image.AlphaType.PREMUL`。
2. `srcPixelFormat` 与 `pixelFormat` 继续保持 `RGBA_8888`，与 Native 导出通道顺序一致。
3. 禁止把这组 Native 预乘字节标记为 `UNPREMUL`，也不依赖 PixelMap 的隐式/default alpha 推断。
4. PixelMap 的 width/height 继续直接取自同一个 Native render result，避免像素契约与几何契约分离。
5. replay 同时固定 Native 创建、实际格式验证、ReadPixels 目标格式与 ArkTS PixelMap alphaType，任一端漂移都应失败。
6. 用半透明红色的数值合成模型保留回归证明：正确预乘输入覆盖白底仍为纯红；再次预乘则会明显变暗。

## 结果

- Native Bitmap、ReadPixels 目标缓冲与 ArkTS PixelMap 三层统一为 premultiplied RGBA。
- 半透明彩色公式边缘不再依赖平台默认解释，避免跨层二次预乘造成暗边。
- alpha association 成为可静态审计、可 replay 回归的显式协议，而不是隐藏在 opaque/黑色公式中的偶然正确。
- 原版 Bitmap/Canvas 内部一致的合成语义，在 Harmony 跨 Native/ArkTS 边界后仍保持闭环。

## 边界

- 本决策只固定 alpha association，不替代真机对色彩空间、GPU 上传与最终合成路径的验证。
- 完全不透明或纯黑公式不足以验证该修复；真机应使用半透明红、绿、蓝边缘并在浅色与深色背景分别检查。
- 若未来 Native 改为 `UNPREMUL` 或其他像素格式，必须同时修改 Bitmap、ReadPixels、PixelMap 与 replay，不能只改单端。
