# ADR-0197：Native Math 文本必须保留原版字体样式与基线度量

## 状态

Accepted，2026-08-14。

## 问题

Harmony 的 `HarmonyFont` 与 `HarmonyTextLayout` 虽可绘制公式字体，但与 Notability 1.0.3 的 GLMath Android port
存在三处会直接改变视觉输出的偏差：

- `deriveFont(int style)` 丢弃 style，字体相等判断也忽略 style；`	extbf{}`、`	extit{}` 和
  `	extbf{	extit{}}` 因此退化为普通体；
- 文本布局使用 Native Drawing 返回的 tight glyph bounds，并把 `max(advance, tightWidth)` 当宽度；原版使用
  `measureText + fontMetrics.ascent/descent`，其高度与深度围绕 baseline 独立计算；
- Harmony 无条件把 `Stroke.miterLimit` 写入 Pen，包括默认值 0；原版只在 miterLimit 大于 0 时覆盖平台默认值。

这些偏差通常不会导致崩溃，却会造成公式中普通文字、外部 Unicode 字符、粗斜体、上下标与包围框的宽高、baseline、
笔画拐角不接近原版。

## 原版证据

- `decompiled_1.0.3/.../GLMathTextMeasurer.java` 明确返回：
  `paint.measureText(text), fontMetrics.ascent, fontMetrics.descent`。
- 原版 arm64 `libglmath.so` 的 `tex::port::TextLayout_Android::getBounds()` 反汇编确认构造：
  `x = 0`、`y = ascent`、`w = advance`、`h = descent - ascent`。
- 同一原版 so 的 `Font_Android` 保存 file、style、size；`deriveFont(style)` 复制 file/size 并替换 style，
  `operator==` 同时比较三者。
- `decompiled_1.0.3/.../lz4.java` 对空路径使用 `Typeface.defaultFromStyle(style)`，对文件字体使用
  `Typeface.create(fileTypeface, style)`；加载失败也回退到对应 style 的默认字体。
- `decompiled_1.0.3/.../MathDrawTarget.java` 绘字时以 fontFile/fontStyle/fontSize 取得 Typeface，并且只在
  `miterLimit > 0` 时调用 `setStrokeMiter()`。
- MicroTeX `TextRenderingBox` 以 `-bounds.y` 计算 height，并以 `bounds.h - height` 计算 depth；把 tight glyph
  bounds 替代 font metrics 会直接改变公式盒模型，而不仅是测量实现细节。

## 决策

1. `HarmonyFont` 必须保存 `style_`；从文件创建使用 `PLAIN`，系统 fallback 创建保留调用方请求的 style。
2. `deriveFont(style)` 必须保留 file 与 size 并应用新 style，字体相等判断必须包含 style。
3. Harmony Native Drawing 没有 Android `Typeface.create(base, style)` 的同形接口，因此在 Font 上使用平台提供的
   fake bold 与 text skew：
   - `BOLD` → `OH_Drawing_FontSetFakeBoldText(true)`；
   - `ITALIC` → `OH_Drawing_FontSetTextSkewX(-0.25)`；
   - `BOLDITALIC` 同时启用两者。
4. 字体 style 必须同时影响 measure 与 draw；不能仅在 Canvas 绘制时做视觉变形，否则盒宽与实际像素不一致。
5. `HarmonyTextLayout::getBounds()` 使用 `OH_Drawing_FontMeasureText(..., bounds=nullptr)` 取得 advance，并用
   `OH_Drawing_FontGetMetrics()` 取得 ascent/descent。
6. 布局盒固定为原版结构：`x=0`、`y=ascent`、`w=advance`、`h=descent-ascent`。
7. advance、ascent、descent 必须为有限值，advance 不得为负且 descent 必须大于 ascent；无效度量返回空布局。
8. 默认 miterLimit 0 不写入 Pen；仅正值覆盖平台默认斜接限制。
9. 保持公式主字体文件、字号、颜色、抗锯齿、subpixel 与已有框内 fit 算法不变。

## 结果

- `	extbf`、`	extit` 与粗斜体组合不再全部退化为普通字形。
- 字体样式参与测量与绘制，避免“盒宽仍是普通体、像素却是粗斜体”的二次错位。
- 文本公式盒重新以 baseline 的 ascent 与 descent 分配 height/depth，上下标、分数旁文字和混合 Unicode 更接近原版。
- 空格与 advance 宽度不再被 tight glyph bounds 错误吞掉或替换。
- 默认 miter join 不再被无效 0 限制改变。

## 边界

- fake bold/skew 是 Harmony Native Drawing 对 Android styled Typeface 的最接近底层适配；具体字重、倾斜角和 hinting
  仍可能与 Android 字体栅格器有细微差异。
- 桌面 replay 锁定原版控制流和盒模型，HAP 构建验证 API，但像素级 baseline 与 glyph 对齐仍需真机截图比较。
- 系统 fallback 字体由 HarmonyOS 提供，Android 与 Harmony 的默认字符覆盖、fallback 顺序和字形本身不可能完全相同。
- 外部语言与 emoji/fallback glyph 的 font metrics 仍需设备样本确认。
