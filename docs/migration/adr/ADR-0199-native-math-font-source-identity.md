# ADR-0199：Native Math 必须保留字体来源并恢复 externalfont

## 状态

Accepted，2026-08-15。

## 问题

Harmony 的 `HarmonyFont` 已经能够从文件创建 Typeface、应用 bold/italic，并在失败时回退默认字体；但
`Font::_create(const std::string &name, ...)` 完全忽略 `name`，始终以空字符串创建字体。

这会造成：

- MicroTeX 的 `\externalfont{...}` 宏失效，任何请求的字体文件都不会被尝试加载；
- 测量和绘制无法携带原版的 `fontFile` 身份；
- 不同字体来源在进入 `HarmonyFont` 前就被合并；
- `deriveFont()` 和 equality 虽已支持 file/style/size，却只能传播错误的空来源。

## 原版证据

- MicroTeX `externalfont` 宏调用 `TextRenderingBox::setFont(name)`，后者调用
  `Font::_create(name, PLAIN, 10)`。
- 原版 arm64 `libglmath.so`：
  - `Font::create @ 0x2200b8` 创建 40-byte `Font_Android`，复制传入字符串，并保存 style 0 与 size；
  - `Font::_create(name, style, size) @ 0x220140` 同样复制 name，并保存 style/size；
  - `Font_Android::deriveFont @ 0x221280` 复制原字体字符串和 size，只替换 style；
  - `Font_Android::operator== @ 0x221358` 依次比较字符串、style 和 size；
  - `TextLayout_Android::getBounds @ 0x220db8` 与 `Graphics2D_Android::drawWide @ 0x22074c`
    都把该字符串、style、size 交给 Java bridge。
- `GLMathTextMeasurer.measure()` 与 `MathDrawTarget.drawText()` 都把 `fontFile/fontStyle/fontSize`
  交给 `lz4`。
- `lz4` 的原版解析规则为：
  - 空字符串：`Typeface.defaultFromStyle(style)`；
  - 非空字符串：先 `Typeface.createFromFile(path)`，再应用 style；
  - 文件加载抛出异常：记录日志并回退 `Typeface.defaultFromStyle(style)`；
  - cache key 同时包含 path 与 style。

## 决策

1. `Font::_create(name, style, size)` 必须把 `name` 原样交给 `HarmonyFont`，不得清空、规范化或映射。
2. `HarmonyFont` 对空来源直接创建默认 Typeface；对非空来源先调用
   `OH_Drawing_TypefaceCreateFromFile()`，失败再创建默认 Typeface。
3. 无论文件加载成功还是回退，bold/italic 都必须继续作用于 measure 与 draw。
4. `deriveFont(style)` 必须保留来源和 size；字体 equality 必须包含来源、style、size。
5. `Font::create(file, size)` 继续把资源字体文件作为 PLAIN 字体创建，不改变数学字形加载路径。
6. 不把 `Serif` / `SansSerif` 擅自映射到 Harmony 系统字体族：原版 Android bridge 会先把非空字符串
   当作文件路径，失败后回退默认字体。两者可能视觉相同，但 native 身份仍保持不同。

## 结果

- `\externalfont{有效字体路径}` 可重新影响 text 公式的测量与绘制。
- 无效路径按原版语义安全回退，并保留请求的 bold/italic。
- 测量与绘制共享同一来源/style/size，不再出现一端加载文件、另一端使用默认字体的协议断裂。
- 字体对象的身份与原版一致，不同来源不会在 `_create()` 入口被提前合并。

## 边界

- Harmony Native Drawing 与 Android Typeface 的字体 hinting、fallback glyph 和合成样式仍可能有像素差异。
- 本阶段恢复来源传播，不新增跨对象 Typeface cache；对象级复用和性能可在有真机 profiling 证据后独立处理。
- `Serif` / `SansSerif` 的视觉 fallback 看似相同是原版 Android resolver 的结果，不应据此删除来源身份。
