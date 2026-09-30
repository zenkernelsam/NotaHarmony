# ADR-1305 — 工具条字形按 fill+outline 两层近似（highlight/shadow/overlay 暂缓）

## 状态

Accepted（已落地，含已知边界）。

## 决策

编辑器工具条字形以原版 `m4f` 五层中的 **fill + outline 两层**渲染：

- 由 `ui_designsystem__<tool>_{fill,outline}.xml` 逐字节提取 pathData 进
  `ToolGlyphs.ets`。
- `ToolGlyph` 用 `Shape`+`viewPort({24,24})`+`Path` 叠层：fill 染
  `brushColor`（pen/pencil/highlighter，对应 `cq.h`）或 contentColor（其余，
  对应 `rz1.c` 状态色），outline 以 contentColor 描边。
- `toolGlyphKey` 覆盖全部 ToolType；`eraser_whole`/`eraser_partial` 为单图标。

## 刻意暂缓（非丢功能）

`m4f` 的 highlight / shadow / overlay 三层（高光/投影/叠加描边深度）未提取：

- 三层在 `tn8`/`rz1.c` 深层 lambda 中按状态/颜色动态合成，混淆后难以确定性
  复现其 z-order 与混合模式；
- 设备/模拟器验证被禁，无法比对像素。
- 图标**语义**（可辨识工具形）、**颜色联动**（笔刷色进 fill）、**激活描边**
  均已正确；缺的仅是立体高光层次。

后续若要补齐：从 `<tool>_{highlight,shadow,overlay}.xml` 提取同法生成，按
m4f 字段序 shadow→fill→highlight→overlay→outline 叠层即可，数据结构与
组件已为此预留。

## 依据

- 证据：`docs/migration/evidence/phase-1368-editor-toolbar-glyphs.md`
- Replay：`d02-original-editor-toolbar-glyphs.mjs`（55/55）
