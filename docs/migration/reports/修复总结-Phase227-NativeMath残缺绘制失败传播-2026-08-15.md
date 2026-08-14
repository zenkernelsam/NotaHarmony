# Phase 227 修复总结：Native Math 残缺绘制失败传播

## 发现

Phase 226 保护 N-API 结果构造后，继续核对原版 `nativeDraw` 完整成功语义，发现 Harmony 的图元失败仍会产生坏缓存：

- TextBlob、Font、Rect、RoundRect 或绘图资源失败时，HarmonyGraphics 只 return 当前方法；
- 外层 Render 不知道某个字符、分数线、边框或装饰已经丢失，仍复制 pixels 并返回 valid=true；
- ArkTS 随后会把残缺 PixelMap/ImageBitmap 放入 Math 缓存，内存恢复后也可能长期显示错误结果。

## 原版依据

- `GLMathNative.nativeDraw` 用一个 boolean 表示整次公式绘制结果。
- `MathDrawTarget` 的图元方法不自行吞异常；Canvas/Typeface/Paint 故障留给 JNI 边界。
- 原版 arm64 `nativeDraw @ 0x221bc8` 在完整 `TeXRender::draw` 后检查 JNI pending exception；存在异常时返回
  false，不把部分完成的 Bitmap 当作成功。
- `p18` 只在 true 时返回 Bitmap；false 时 recycle 整张临时 Bitmap 并返回 null。

## 修复

- HarmonyGraphics 新增 sticky `failed_` 与 `failed()`。
- 空字符串绘制保留合法 no-op。
- 非空文字缺少 Canvas/Brush/Font/native Font 时标记整次绘制失败。
- TextBlob 创建失败标记失败，不再静默丢字。
- drawLine 缺少必需资源时标记失败。
- drawRect/fillRect 的资源或 Rect 创建失败时标记失败。
- drawRoundRect/fillRoundRect 的资源、Rect 或 RoundRect 创建失败时标记失败，并继续正确释放已创建 Rect。
- Render 在 `render->draw()` 后立即检查 sticky failure；失败时返回 `formula drawing failed`。
- failure 检查位于 ArrayBuffer、memcpy 和成功对象构造之前，残缺 pixels 不会离开 native 层。
- 更新既有 `d02-native-math-allocation-safety.mjs`，将 primitive guard 提升为“guard + sticky failure”。
- 新增 `d02-native-math-partial-draw-failure.mjs`，锁定原版整次 boolean/recycle、各图元失败传播、copy 前拒绝与
  作用域回收。
- 新增 `ADR-0204-native-math-partial-draw-failure-propagation.md`。

## 修改文件

- `note/src/main/cpp/nota_math.cpp`
- `docs/migration/replays/d02-native-math-allocation-safety.mjs`
- `docs/migration/replays/d02-native-math-partial-draw-failure.mjs`
- `docs/migration/adr/ADR-0204-native-math-partial-draw-failure-propagation.md`
- `docs/migration/reports/修复总结-Phase227-NativeMath残缺绘制失败传播-2026-08-15.md`

## 验证

- partial draw failure 专项 replay：`TOTAL=15 FAILED=0`。
- 更新后的 allocation safety replay：`TOTAL=12 FAILED=0`。
- 全部 Math replay：`MATH_REPLAY_FILES=18 FAILED=0`。
- 全量桌面 replay：`REPLAY_FILES=214 FAILED=0`。
- `note@default assembleHap`：Native Ninja 与 PackageHap 通过，`BUILD SUCCESSFUL in 4 s 505 ms`。
- `note@ohosTest assembleHap`：通过，`BUILD SUCCESSFUL in 1 s 775 ms`。
- `git diff --check` 通过。
- 未启动设备、模拟器、虚拟机或 Hypium。

## 真机待测

- 故障注入 TextBlob 创建失败，确认整个公式返回失败且不会写入缓存。
- 故障注入 Rect/RoundRect 创建失败，确认 boxed/fbox/根号或装饰公式不会留下局部图形。
- 字体文件损坏或 Typeface/Font 创建失败时，确认公式安全留空并可在资源恢复、重启后重新生成。
- 连续内存压力下观察失败 bitmap、Canvas、Pen/Brush、PixelMap 与 ImageBitmap 是否全部回落。
- 正常公式覆盖文本、分数、根号、矩阵、圆角框和多色命令，确认 sticky failure 没有误报合法 no-op。
