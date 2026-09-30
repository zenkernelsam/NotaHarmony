# Phase 1386 — 原版 brush-style 波形样张证据

## 原版样式选项（decompiled_1.0.3）

`x4j.java::a(pd8, y31, z, z2, z3, t42, i)`：
```
switch (y31.ordinal()) {
  0 -> rh8.K(R.drawable.ui_tools__brushstyle_mono)   // 等粗
  1 -> rh8.K(R.drawable.ui_tools__brushstyle_taper)  // 渐细
  2 -> rh8.K(R.drawable.ui_tools__brushstyle_dashed) // 虚线
  3 -> rh8.K(R.drawable.ui_tools__brushstyle_dotted) // 点状
}
go5.b(h1aVarK /* painter */, y31Var.name() /* a11y */,
      bfd.d(md8Var, 1.0f) /* modifier */, j3 /* tint */, ...)
```
→ 每个样式选项是一枚图标按钮，图标为该样式绘制的波形样张；样式名仅作无障碍描述。

## 资源提取

`res/drawable/ui_tools__brushstyle_{mono,taper,dashed,dotted}.xml`，viewport 均 44×24：

| 样式 | 渲染 | 说明 |
|------|------|------|
| mono | `fillColor=0` + `strokeColor=#444f60` + `strokeWidth=3` | 开放等粗波形（stroked） |
| taper | `fillColor=#444f60` | 渐细楔形波形（filled） |
| dashed | `fillColor=#444f60`，多子路径 | 虚线段波形 |
| dotted | `fillColor=#444f60`，多子路径 | 点阵波形 |

`_gen_brushstyles.cjs` 逐字提取 → `BrushStyleGlyphs.ets`，dash/dot 多 `<path>` 已拼接。

## Harmony 落点

`EditorToolbar.ets`：
- `brushStyleGlyph(style)`：`BrushStyle` 序号 → `brushstyle_<mono|taper|dash|dot>` key。
- `@Builder BrushStyleGlyphView(style, color)`：`Shape{Path.commands(g.d)}`，
  `stroked` 走 `.stroke(color)` 否则 `.fill(color)`，`viewPort 44×24` → 40×22。
- `StyleButton`/`SelectionStyleButton`：`Button(label)` → `Button(){glyph}`；
  选中态 `onAccent`/`textPrimary` 着色沿用原 `fontColor` 逻辑，
  `.accessibilityText(label)` 保留样式名（`label: ResourceStr` → `Resource`）。

## 验证

- Replay `d02-original-brush-style-glyphs.mjs`：23/23。
- `note@default` assembleHap：成功。
- 全量基线：1239/1239。
