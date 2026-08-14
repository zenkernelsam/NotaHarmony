# Phase 228 修复总结：Native Math 位图行布局与格式导出

## 发现

Phase 227 阻止残缺公式缓存后，继续核对 Native Bitmap 到 ArkTS PixelMap 的桥接，发现像素复制仍假设内部布局：

- `BitmapGetPixels()` 返回内部地址后直接 memcpy `width * height * 4`；
- 没有验证实际 color format 与 alpha format；
- 没有 row bytes/stride 信息，却默认每行紧密排列；
- 若平台内部行跨度更大，首行 padding 会被当作下一行像素，导致错行、截断或错色。

## 原版与平台依据

- 原版 `p18` 在 Android ARGB_8888 Bitmap 上建立 Canvas 并直接绘制，未把内部存储裸地址重新解释为紧密数组。
- Harmony Native Drawing 文档明确允许 bitmap pixel row size 大于最小行长度。
- SDK 提供带 `dstRowBytes` 的 `OH_Drawing_BitmapReadPixels()`，由平台把内部行布局安全导出到目标缓冲。
- 当前项目 compatible/target SDK 为 6.0.1(21)，支持 Bitmap format/alpha 查询和 ReadPixels。
- ArkTS `createPixelMapSync` 按 width/height 和 RGBA_8888 读取紧密 ArrayBuffer，native 必须交付无内部 padding 的行。

## 修复

- Bitmap build 后除 backing pixels、width、height 外，新增实际格式验证：
  - `COLOR_FORMAT_RGBA_8888`；
  - `ALPHA_FORMAT_PREMUL`。
- 显式定义目标 `rowBytes = pixelWidth * 4`。
- ArrayBuffer 长度改为 `rowBytes * pixelHeight`。
- 建立匹配尺寸、RGBA_8888 与 premultiplied alpha 的 `OH_Drawing_Image_Info`。
- 用 `OH_Drawing_BitmapReadPixels(..., destination, rowBytes, 0, 0)` 导出紧密行。
- ReadPixels false 时返回 `formula pixel transfer failed`，不构造成功结果。
- 删除内部地址到目标缓冲的连续 `std::memcpy` 与 `<cstring>` 依赖。
- 更新 allocation safety、N-API result safety、partial draw failure 三条既有 replay 的像素出口断言。
- 新增 `d02-native-math-bitmap-row-layout.mjs`，覆盖原版 Bitmap 语义、SDK 版本、实际格式、packed rowBytes、
  ReadPixels 顺序与 padding 数值模型。
- 新增 `ADR-0205-native-math-bitmap-row-layout-and-format.md`。

## 修改文件

- `note/src/main/cpp/nota_math.cpp`
- `docs/migration/replays/d02-native-math-allocation-safety.mjs`
- `docs/migration/replays/d02-native-math-napi-result-safety.mjs`
- `docs/migration/replays/d02-native-math-partial-draw-failure.mjs`
- `docs/migration/replays/d02-native-math-bitmap-row-layout.mjs`
- `docs/migration/adr/ADR-0205-native-math-bitmap-row-layout-and-format.md`
- `docs/migration/reports/修复总结-Phase228-NativeMath位图行布局与格式导出-2026-08-15.md`

## 验证

- bitmap row layout 专项 replay：`TOTAL=14 FAILED=0`。
- 全部 Math replay：`MATH_REPLAY_FILES=19 FAILED=0`。
- 全量桌面 replay：`REPLAY_FILES=215 FAILED=0`。
- `note@default assembleHap`：Native Ninja 与 PackageHap 通过，`BUILD SUCCESSFUL in 4 s 84 ms`。
- `note@ohosTest assembleHap`：通过，`BUILD SUCCESSFUL in 1 s 880 ms`。
- `git diff --check` 通过。
- 未启动设备、模拟器、虚拟机或 Hypium。

## 真机待测

- 使用奇数宽度、非 8/16/64 对齐宽度的公式位图，逐行检查是否存在错位或横向撕裂。
- 绘制红、蓝、半透明黑与半透明彩色公式，确认无红蓝互换和 premultiplied alpha halo。
- 对比缓存首次生成与缓存命中结果，确认 ReadPixels 导出没有引入字节变化。
- 故障注入 ReadPixels false，确认不会创建 PixelMap/缓存，也不会泄漏 native 资源。
- 大尺寸公式连续导出，观察 row-aware copy 的性能与内存峰值是否可接受。
