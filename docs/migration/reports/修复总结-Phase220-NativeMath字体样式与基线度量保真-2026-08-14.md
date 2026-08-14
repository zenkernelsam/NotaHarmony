# Phase 220 修复总结：Native Math 字体样式与基线度量保真

## 发现

Phase 219 完成 native 分配失败回收后，继续把 Harmony `HarmonyFont/HarmonyTextLayout` 与原版 1.0.3 的
`GLMathTextMeasurer`、`MathDrawTarget` 和 arm64 `libglmath.so` 逐项对照，确认现有公式虽然能出图，但文本盒模型和字体
样式尚未按原版实现：

- `deriveFont()` 忽略 bold/italic 参数；字体相等判断也看不到 style；
- `_create(..., style, size)` 丢弃 style，导致 text 系列宏全部使用普通体；
- TextLayout 采用 tight glyph bounds，而原版使用 advance + ascent/descent；
- tight bounds 会改变 `TextRenderingBox` 的 height/depth，继而影响 baseline、上下标、分数及整体 measure；
- 默认 miterLimit=0 被直接写入 Harmony Pen，与原版“0 表示不覆盖平台默认值”不同。

## 原版依据

- `GLMathTextMeasurer.measure()` 返回 `measureText(text), ascent, descent`。
- 原版 `libglmath.so` 反汇编进一步确认 `TextLayout_Android::getBounds()` 写入
  `x=0, y=ascent, w=advance, h=descent-ascent`。
- 原版 so 的 `Font_Android` 保存并比较 file/style/size，`deriveFont(style)` 会真正传播样式。
- `lz4.java` 使用 `Typeface.defaultFromStyle(style)` 或 `Typeface.create(fileTypeface, style)`。
- `MathDrawTarget.drawText()` 把 fontStyle 交给字体 resolver；`setStroke()` 只在 miterLimit 正数时覆盖 Paint。

## 修复

- `HarmonyFont` 新增 `style_`：
  - 构造器接收 file/style/size；
  - `deriveFont(style)` 保留 file/size 并应用新 style；
  - equality 同时比较 file、style、size；
  - 文件字体入口以 `PLAIN` 创建；系统文字入口保留 MicroTeX 请求 style。
- 使用 Native Drawing 的字体级样式能力：
  - bold 启用 `OH_Drawing_FontSetFakeBoldText()`；
  - italic 使用 `OH_Drawing_FontSetTextSkewX(-0.25)`；
  - 粗斜体同时生效，因此 measure 与 draw 共享同一个 styled Font。
- 重写 `HarmonyTextLayout::getBounds()`：
  - 以 `OH_Drawing_FontMeasureText(..., nullptr, &width)` 获取 advance；
  - 以 `OH_Drawing_FontGetMetrics()` 获取 ascent/descent；
  - 输出原版 `x=0, y=ascent, w=width, h=descent-ascent`；
  - 拒绝非有限、负宽或颠倒的 metrics。
- `setStroke()` 仅在 `miterLimit > 0` 时写入 Harmony Pen，恢复原版默认值语义。
- 新增 `d02-native-math-font-fidelity.mjs`，锁定 Java 原版证据、Harmony style 传播、字体身份、bold/italic、
  baseline metrics、miter 门禁与 TextRenderingBox 桌面模型。
- 新增 `ADR-0197-native-math-font-style-baseline-fidelity.md`。

## 修改文件

- `note/src/main/cpp/nota_math.cpp`
- `docs/migration/replays/d02-native-math-font-fidelity.mjs`
- `docs/migration/adr/ADR-0197-native-math-font-style-baseline-fidelity.md`
- `docs/migration/reports/修复总结-Phase220-NativeMath字体样式与基线度量保真-2026-08-14.md`

## 验证

- Native Math 字体/基线保真专项 replay：`TOTAL=12 FAILED=0`。
- Native Math 分配安全专项 replay：`TOTAL=12 FAILED=0`。
- native 数学引擎 replay：`TOTAL=7 FAILED=0`。
- 原版 Math 框适配 replay：`TOTAL=16 FAILED=0`。
- Math 位图缓存生命周期 replay：`TOTAL=12 FAILED=0`。
- 本地 Math 插入、LaTeX 编辑、consumer 与 block replay 全部通过。
- 全量桌面 replay：`REPLAY_FILES=207 FAILED=0`。
- `note@default assembleHap`：Native Ninja、PackageHap 通过，`BUILD SUCCESSFUL in 5 s 663 ms`。
- `note@ohosTest assembleHap`：OhosTest 与 native 构建链通过，`BUILD SUCCESSFUL in 563 ms`。
- `git diff --check` 通过，仅有工作区 LF 将来转换为 CRLF 的提示。
- 未启动设备、模拟器或虚拟机。

## 未闭环与真机待测

- 对比原版与 Harmony 的 `\text{abc}`、`\textbf{abc}`、`\textit{abc}`、粗斜体组合截图，确认 weight、skew、
  advance 与 baseline 接近。
- 测试含空格、上下行字形（如 `Agjp`）、CJK、希腊文、西里尔文和 emoji/fallback glyph 的文本公式。
- 将 text 公式放入上下标、根号、分数、矩阵和旋转盒，确认新的 ascent/descent 不产生裁切或额外空白。
- 检查细边框、boxed/fbox 和旋转装饰的 miter join，确认默认 0 不覆盖平台限制后拐角更接近原版。
- 若真机像素显示 fake italic 角度偏大或偏小，再以原版截图校准 `ITALIC_SKEW_X`，但不得回退 style 传播和基线盒。
