# ADR-1322：画笔样式选项使用原版 brushstyle 波形样张

## 状态

已接受（Phase 1386）。

## 背景

编辑器画笔样式选择器（`StyleButton` / `SelectionStyleButton`）此前渲染文本标签
（"Mono/Taper/Dash/Dots"）。对照原版，样式选项显示 `ui_tools__brushstyle_<style>`
**笔画波形样张**（44×24 波浪线，以该样式绘制），样式名仅作无障碍文本，不显示文字。

## 原版证据

- `x4j.java::a(...)`：`go5.b(h1aVarK /* brushstyle painter */, y31Var.name() /* a11y */,
  bfd.d(md8Var,1.0f), j3 /* color */, ...)` —— 每个样式选项是一枚图标按钮，
  painter 取 `R.drawable.ui_tools__brushstyle_{mono,taper,dashed,dotted}`。
- 4 个 drawable（`res/drawable/ui_tools__brushstyle_*`，`viewport 44×24`）：
  - `mono` = 等粗波形，开放路径 `fillColor=0 + strokeColor + strokeWidth=3`（stroked）。
  - `taper` = 渐细波形，`fillColor` 闭合填充。
  - `dashed` = 虚线波形，`fillColor` 多子路径。
  - `dotted` = 点状波形，`fillColor` 多子路径。
- `y31` 序号（0=mono/1=taper/2=dash/3=dot）与 Harmony `BrushStyle` 序号一致。

## 决策

1. 新增 `note/src/main/ets/ui/components/BrushStyleGlyphs.ets`，导出
   `BRUSH_STYLE_GLYPHS`（`brushstyle_<mono|taper|dash|dot>` → `{d, stroked, sw, vw, vh}`），
   `pathData` 逐字保留（`_gen_brushstyles.cjs` 提取）。
2. `EditorToolbar` 新增 `brushStyleGlyph(style)`（`BrushStyle` → glyph key）与
   `@Builder BrushStyleGlyphView(style, color)`：Shape+Path，`stroked` 走 `.stroke(color)`
   否则 `.fill(color)`，`viewPort 44×24` 渲染为 40×22。
3. `StyleButton`/`SelectionStyleButton` 由 `Button(label)` 改为
   `Button(){BrushStyleGlyphView}`；着色沿用原选中态逻辑
   （selected → `onAccent`，unselected → `textPrimary`，叠于 accent/control 底色上）。
4. 样式名由 `.accessibilityText(label)` 承载；`label` 参数类型 `ResourceStr` →
   `Resource`（ArkUI `accessibilityText` 需具体 `Resource`，调用方均传 `$r()`）。

## 后果

- 样式选项视觉与原版对齐：以该样式绘制的波形样张直观区分 mono/taper/dash/dot。
- 样式名仍由无障碍文本提供；选中态、taper 门控（`selectionVariableStyleEnabled`）、
  `setBrushStyle`/`onSelectionStyle` 回调不变。
- 新增 Replay `d02-original-brush-style-glyphs.mjs`（23 断言）锁定 4 字形、
  stroked/filled 渲染、样式映射与两处按钮。

## 参考

- `docs/migration/evidence/phase-1386-original-brush-style-glyphs.md`
- `docs/migration/reports/phase-1386-original-brush-style-glyphs.md`
- `docs/migration/replays/d02-original-brush-style-glyphs.mjs`
