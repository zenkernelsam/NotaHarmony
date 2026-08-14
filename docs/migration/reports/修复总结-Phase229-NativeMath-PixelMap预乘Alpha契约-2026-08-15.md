# Phase 229 修复总结：Native Math PixelMap 预乘 Alpha 契约

## 发现

Phase 228 已把 Native Bitmap 安全导出为紧密的 `RGBA_8888 + PREMUL` 字节，但 ArkTS 创建 PixelMap 时只声明了
`srcPixelFormat` 与 `pixelFormat`，没有声明 `alphaType`。这使 Native 已预乘的 RGB 字节在最后一个跨语言边界重新落入
隐式解释：平台若按非预乘输入转换，半透明彩色字形边缘会再次乘 alpha，产生发暗、脏边或 halo。

该问题对不透明像素和常见黑色公式不明显，却会破坏彩色、抗锯齿与半透明公式的原生观感。

## 原版与平台依据

- 原版 `p18` 在 `Bitmap.Config.ARGB_8888` Bitmap 上建立 Canvas 并直接绘制，结果没有离开 Bitmap/Canvas 一致的
  alpha 合成语义。
- Harmony Native Bitmap 明确创建为 `COLOR_FORMAT_RGBA_8888 + ALPHA_FORMAT_PREMUL`，并验证实际 alpha format。
- `OH_Drawing_BitmapReadPixels()` 的目标 Image Info 同样为 `ALPHA_FORMAT_PREMUL`，所以 ArkTS 收到的是预乘字节。
- `RGBA_8888` 不携带“RGB 是否已乘 alpha”的信息；PixelMap 必须通过独立 `alphaType` 选项声明。

## 修复

- 在 `OriginalMathEngine.render()` 的 `image.createPixelMapSync()` options 中新增：
  `alphaType: image.AlphaType.PREMUL`。
- 保持源、目标 PixelMap format 都为 `RGBA_8888`，与 Native channel layout 一致。
- 新增 `d02-native-math-pixelmap-alpha-contract.mjs`，覆盖：
  - 原版 ARGB_8888 Bitmap/Canvas 绘制语义；
  - Native Bitmap 创建与实际 premultiplied alpha 验证；
  - ReadPixels 目标缓冲的 premultiplied RGBA 契约；
  - ArkTS PixelMap 显式 `PREMUL` 且禁止误标 `UNPREMUL`；
  - PixelMap 尺寸来自同一 Native render result；
  - 半透明红色正确合成与二次预乘变暗的数值模型。
- 新增 `ADR-0206-native-math-pixelmap-premultiplied-alpha-contract.md`，固定跨 Native/ArkTS 的 alpha 契约。

## 修改文件

- `note/src/main/ets/rendering/OriginalMathEngine.ets`
- `docs/migration/replays/d02-native-math-pixelmap-alpha-contract.mjs`
- `docs/migration/adr/ADR-0206-native-math-pixelmap-premultiplied-alpha-contract.md`
- `docs/migration/reports/修复总结-Phase229-NativeMath-PixelMap预乘Alpha契约-2026-08-15.md`

## 验证

- PixelMap alpha contract 专项 replay：`TOTAL=10 FAILED=0`。
- 全部 Math replay：`MATH_REPLAY_FILES=20 FAILED=0`。
- 全量桌面 replay：`REPLAY_FILES=216 FAILED=0`。
- `note@default assembleHap`：ArkTS 与 HAP 构建通过，`BUILD SUCCESSFUL in 9 s 668 ms`。
- `note@ohosTest assembleHap`：ArkTS、Native Ninja 与 PackageHap 通过，`BUILD SUCCESSFUL in 7 s 802 ms`。
- `git diff --check` 通过。
- 未启动设备、模拟器、虚拟机或 Hypium。

## 真机待测

- 使用半透明红、绿、蓝公式，在白色、浅色、深色背景分别观察抗锯齿边缘是否发暗或出现 halo。
- 对比首次 Native 渲染、PixelMap/ImageBitmap 展示与缓存命中结果，确认各路径 alpha 观感一致。
- 检查完全不透明彩色公式与黑色公式，确认显式 PREMUL 没有引入色偏或透明度变化。
- 对细线、小字号与高 DPI 公式做截图放大比较，因为二次预乘最容易出现在这些边缘像素。
