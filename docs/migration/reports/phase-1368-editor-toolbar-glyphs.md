# Phase 1368 — 编辑器工具条改用原版工具图标

## 摘要
原版工具条每个工具是 `m4f` 分层字形（outline/highlight/shadow/overlay/fill），
主条经 `cq.h(m4f, brushColor,…)` 给 pen/pencil/highlighter 染笔刷色、`rz1.c`
渲染其余。Harmony 原是 `Button(label)` 文字按钮，丢字形与颜色联动。本 Phase
由原版 11 个 `ui_designsystem__<tool>_{fill,outline}` 矢量逐字节提取 pathData
生成 `ToolGlyphs.ets`，新增 `ToolGlyph`（`Shape`+`viewPort(24×24)` 定标缩放，
叠 fill 填色 + outline 描边 `Path`），`toolGlyphKey` 按 ToolType 选形；
`StateToolButton`/`EraserToolButtons` 改图标钮，标签留作 `accessibilityText`。
边界：highlight/shadow/overlay 三层暂近似为 fill+outline（ADR-0789）。
专项 d02-original-editor-toolbar-glyphs 55/55。
