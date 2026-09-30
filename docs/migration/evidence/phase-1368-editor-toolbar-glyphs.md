# Phase 1368 — 编辑器工具条渲染原版 ui_designsystem__<tool> 图标

## 原版证据（`x5f` 主条 → `cq.h` / `rz1.c` → `m4f`/`tn8`）

原版编辑器工具条每个工具显示一个分层 `m4f` 字形，不是文字按钮：

- `m4f` 数据结构五层：`a=outline`、`b=highlight`、`c=shadow`、`d=overlay`、`e=fill`。
- 主条分两渲染器：
  - `cq.h(m4f, brushColor, …)`——pen/pencil/highlighter（及部分橡皮）把
    **fill 层染成当前笔刷色**，随颜色联动；
  - `rz1.c(m4f, …)`——selection/laser/zoom/tape/text 等其余工具按状态色渲染。
- 24dp 视口；fill/outline 源数据在 `res/drawable/ui_designsystem__<tool>_{fill,outline}.xml`。

## 差距

Harmony 原 `StateToolButton`/`EraserToolButtons` 直接 `Button(label)` 文字按钮，
完全丢字形——既无图标也无笔刷色联动，与原版图标条不符。

## 修正

- 由原版 11 个 `<tool>_{fill,outline}` 矢量提取 pathData 生成
  `ToolGlyphs.ets`（逐字节一致；剔除 `M0,0h24v24h-24z` 边界框）。
- 新增 `ToolGlyph` 组件：`Shape`+`viewPort({24,24})` 把 0-24 命令空间确定性地
  缩放至 `size`vp（跨密度安全），内叠 `Path`——`f` 层填色
  （pen/pencil/highlighter 用 `brushColor` 即 `cq.h` 语义，其余用 contentColor），
  `o` 层用 contentColor 描边（保留原版 strokeWidth/round cap+join）。
- `toolGlyphKey(ToolType)` 映射到对应 glyph；`eraser_whole`/`eraser_partial`
  为单图标（stroke-only / fill-only）。
- `StateToolButton` 改图标钮：宽 44×40，`.accessibilityText(label)` 保留标签
  作无障碍描述；`EraserToolButtons` 整笔/局部两钮同样改图标。
- 激活/禁用/点击/Onboarding 提示逻辑不变。

## 已知边界（ADR-0789）

原版 `m4f` 五层中 highlight/shadow/overlay 三层（叠加高光/投影/描边深度）
暂未逐层提取——当前实现为 **fill + outline 两层**近似。图标语义、
笔刷色联动、激活描边均正确；立体感略逊于原版。后续可补三层。

## 验证

- 新增 `d02-original-editor-toolbar-glyphs.mjs`：55/55（glyph 注册、
  fill/outline 存在性、Shape+viewPort、cq.h 笔刷色、accessibilityText、
  无残留 `Button(label)`）。
- `note@ohosTest` assemble 成功，无 ToolGlyph/EditorToolbar/Shape/viewPort 错误。
