# Phase 232 修复总结：Native Math 测量与绘制 Subpixel 契约

## 发现

Phase 231 恢复旋转角度的原版精度后，继续对照 `GLMathTextMeasurer`、`MathDrawTarget` 与 Harmony Font port，发现
文字测量和绘制仍被错误合并为同一个 subpixel Font：

- 原版测量使用 `Paint(1)`；
- 原版绘制使用 `Paint(129)`；
- Harmony 旧实现使用一个始终开启 subpixel 的 `OH_Drawing_Font` 同时 measure 与 draw。

因此 Harmony 的 advance 测量可能受到原版只属于绘制阶段的 subpixel 定位影响，继而改变文字盒宽、上下标位置和
公式整体 fit。

## 原版依据

- `GLMathTextMeasurer.measure()`：`Paint paint = new Paint(1)`。
- `MathDrawTarget`：`textPaint = new Paint(129)`，而 stroke/fill 均为 `Paint(1)`。
- `129 = 1 | 128`，绘制比测量多出 subpixel text flag。
- `TextLayout_Android::getBounds @ 0x220db8` 走 measurer；`Graphics2D_Android::drawWide @ 0x22074c` 走 draw target。
- 两条路径传递相同的 font file/style/size，差异只应保留在平台文字 flags。

## 修复

- `HarmonyFont` 新增 `measureFont_`，与绘制 `font_` 分离。
- 用 `configureNativeFont()` 为两个 handle 统一应用 Typeface、字号、anti-alias、bold 和 italic。
- 绘制 Font 设置 subpixel `true`；测量 Font 设置 subpixel `false`。
- `HarmonyTextLayout::getBounds()` 改为只使用 `measureNative()`。
- `HarmonyGraphics::drawText()` 继续只使用绘制 `native()`。
- 析构时先释放两个 Font，再释放共享 Typeface。
- 更新字体样式与字体来源 replay，并新增 subpixel 契约专项 replay。
- 新增 `ADR-0209-native-math-measure-draw-subpixel-split.md`。

## 编译后二进制核对

default arm64 `libnota_math.so` 的 `HarmonyFont` 构造函数已生成：

- 两次 `OH_Drawing_FontCreate()`；
- 第一次调用 `configureNativeFont` 前把 bool 参数置为 `1`；
- 第二次调用前把 bool 参数置为 `0`；
- `configureNativeFont` 将该 bool 原样交给 `OH_Drawing_FontSetSubpixel()`。

这确认实际产物保留 draw=`true`、measure=`false`，没有被编译器合并或常量传播成同一状态。

## 修改文件

- `note/src/main/cpp/nota_math.cpp`
- `docs/migration/replays/d02-native-math-font-fidelity.mjs`
- `docs/migration/replays/d02-native-math-font-source-identity.mjs`
- `docs/migration/replays/d02-native-math-text-subpixel-contract.mjs`
- `docs/migration/adr/ADR-0209-native-math-measure-draw-subpixel-split.md`
- `docs/migration/reports/修复总结-Phase232-NativeMath测量与绘制Subpixel契约-2026-08-15.md`

## 验证

- subpixel 契约专项 replay：`TOTAL=11 FAILED=0`。
- 字体样式/基线专项 replay：`TOTAL=12 FAILED=0`。
- 字体来源专项 replay：`TOTAL=16 FAILED=0`。
- 分配安全专项 replay：`TOTAL=12 FAILED=0`。
- 残缺绘制失败传播专项 replay：`TOTAL=15 FAILED=0`。
- 全部 Math replay：`MATH_REPLAY_FILES=23 FAILED=0`。
- 全量桌面 replay：`REPLAY_FILES=220 FAILED=0`。
- `note@default assembleHap`：Native Ninja 与 PackageHap 通过，`BUILD SUCCESSFUL in 13 s 721 ms`。
- `note@ohosTest assembleHap`：通过，`BUILD SUCCESSFUL in 1 s 954 ms`。
- `git diff --cached --check`：通过。
- 未启动设备、模拟器、虚拟机或 Hypium。

## 真机待测

- 对比 `\text{iiii llll ....}`、含空格文本与小字号文字的 measure 宽度及最右侧像素。
- 测试 `\textit`、`\textbf`、粗斜体和 externalfont，确认两个 Font handle 的 style 配置没有分叉。
- 测试 CJK、希腊文、西里尔文与 emoji fallback，观察盒宽、baseline 和 glyph 右边缘。
- 把文字放进上下标、分数、根号、矩阵、boxed 与旋转盒，确认布局不再因测量 subpixel 状态产生额外位移。
