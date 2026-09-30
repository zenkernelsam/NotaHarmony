# ADR-1305 — 工具条字形渲染（m4f 五层，fill+outline → 全层）

## 状态

Accepted（已落地）。**Phase 1369 已补齐全部五层**，两层近似作废。

## 决策

编辑器工具条字形渲染原版 `m4f` 完整五层合成（`ho5` 注册表
`a=outline, b=highlight, c=shadow, d=overlay, e=fill`）：

- 由 `ui_designsystem__<tool>_{fill,outline,highlight,shadow,overlay}.xml`
  逐字节提取 pathData 进 `ToolGlyphs.ets`（剔除 `M0,0h24v24h-24z` 边界框）。
- `ToolGlyph` 用 `Shape`+`viewPort({24,24})`+`Path` 叠层，按 `tn8` 使能分支
  顺序 `fill(e)→overlay(d)→highlight(b)→shadow(c)→outline(a)`：
  - fill 染 `brushColor`（pen/pencil/highlighter，对应 `cq.h`）或
    contentColor（其余，`rz1.c` 状态色）；
  - overlay 亮层（白，`dark?0.35:0.75`）、highlight 亮层（白，
    `dark?0.5:0.65`）、shadow 暗层（黑，`dark?0.4:0.25`）——透明度取自
    `tn8`/`gt` 的 `iu1.b(alpha, themeToken)`，亮/暗色即原版 `#ffffff`/`#000000`
    主题令牌近似；
  - outline 以 contentColor 描边（保留 strokeWidth/round cap+join）。
- `toolGlyphKey` 覆盖全部 ToolType；`eraser_whole`/`eraser_partial` 为单图标，
  无 h/s/v 层。

## 残留近似（极小）

- `iu1.b(alpha, ev1.b().b.a/c.a)` 的主题令牌以白/黑字面量近似（原版亦为
  `#ffffff`/`#000000` 基底）；`x90.b(boolValueOf)` 的状态门在工具条使能态
  恒真，故五层恒渲染。
- 激活态 `contentColor=onAccent` 时 fill/outline 变白，亮/暗层仍按主题色
  叠——与原版一致（选中态仍保留笔刷色+立体层）。

## 依据

- 证据：`docs/migration/evidence/phase-1368-editor-toolbar-glyphs.md`、
  `phase-1369-toolbar-glyph-full-layers.md`
- Replay：`d02-original-editor-toolbar-glyphs.mjs`（91/91）
