# Phase 1437 — 1.4.2 笔画样式卡片行 & SHAPE 过期注释闭环

## 原版证据（decompiled_1.4.2）

### 样式行宿主与顺序

- `yxi.java:79-82`（笔/荧光笔设置面板 case0）按序构造四个 `u4h`：
  1. `o81.c` Taper → label `brush_style_variable`、图标 `ui_designsystem__line_style_variable`
  2. `o81.a` Mono → label `brush_style_fixed`、图标 `ui_designsystem__line_style_fixed`
  3. `o81.d` Dash → label `brush_style_dashed`、图标 `ui_designsystem__line_style_dashed`
  4. `o81.b` Dot → label `brush_style_dotted`、图标 `ui_designsystem__line_style_dotted`
- `o81.java` 枚举序 = Mono, Taper, Dash, Dot（持久化序号不变；UI 显示序 ≠ 枚举序）。
- `azm.c`：每个 `u4h` 渲染为 `weight(1f)` 等宽卡片——`qze` 圆角外形、
  `u5n.b` 1.5dp 描边（选中 `a.c` accent / 未选透明）、卡面选中 `a.d.d.a`
  accent-container / 未选 `a.b.b` surface；内容 `c90` 纵排 =
  `i87.b` 24dp 图标 + `d4i.b` 文本标签，着色恒 `a.c.b`。
- `lri`/`ne`：样式行仅挂在实现 `n5h` 的工具上——`csi`(PEN)、`wri`(HIGHLIGHTER)。
- `dwi` SHAPE 分支只发 `h5g` 形状种类条目；`psi`(SHAPE) 不实现 `n5h`；
  `CREATE_SHAPE` 载荷无 line-style 字段 → 原版 SHAPE 面板无线型选择器。

### 图标资产（res/drawable/ui_designsystem__line_style_*.xml）

- `line_style_variable`：24×24 viewport，fillColor=#000000 填充波形。
- `line_style_fixed`：24×24 viewport，fillColor=#00000000 + stroke 1.25 round；
  外层 `group translateX/Y="0.625"`（Harmony 以负视口原点 vx/vy=-0.625 复刻，
  等价于内容 +0.625 平移，pathData 逐字保留内层 path）。
- `line_style_dashed`：填充透明 + stroke 1.25 round 折线簇。
- `line_style_dotted`：fillColor=#000000 圆点簇（a0.625 圆弧对）。

### SHAPE 约束标记（j1k.q）为休眠代码

- `u5g`/`j1k.q`：约束 flag（矩形→正方形、线/箭头→45° 吸附）。
- 全源树（decompiled_1.4.2/sources + resources）搜索 `j1k.m(`、`\.m\(true\)` 至
  `j1k` 上下文的写入点：**零调用者**——setter `m(boolean)` 存在但从未被写。
- `h8d.e` 捕获 pointer metaState（`ihl.c` = metaState&1 = Shift），但仅馈入
  `sgn.Y`/`pba` 选择/输入分支，不进入 SHAPE 拖拽路径。
- 结论：`j1k.q` 在 1.4.2 为 dead code；Harmony `constrain=false` 是精确对齐，
  非缺失功能。启用约束反而是行为发明。

## Harmony 实现

- `note/src/main/ets/ui/components/BrushStyleGlyphs.ets`：
  - 新增 `LINE_STYLE_GLYPHS`（4 枚 1.4.2 矢量，pathData 逐字）。
  - `BrushStyleGlyph` 接口扩展可选 `vx`/`vy` 视口偏移。
  - 1.0.3 `BRUSH_STYLE_GLYPHS`（x4j 波形）保留为历史证据，不再被消费。
- `note/src/main/ets/ui/editor/EditorToolbar.ets`：
  - `lineStyleGlyph()`：BrushStyle→line_style_* 键映射。
  - `LineStyleIconView`：Shape+Path 22px 渲染（24 视口压缩）。
  - `styleCardSelectedBackground()`：accent + #1F 前缀近似 accent-container。
  - `StyleButton`/`SelectionStyleButton`：icon+label 等宽圆角卡片
    （height 46、radius 8、borderWidth 1.5、layoutWeight 1、左右 margin 2、
    accessibilityText=label）。
  - 两行顺序统一为 Variable, Fixed, Dashed, Dotted。
  - 工具行高 40→52；选区设置容器高 64→104。
  - Taper 选区门控 `selectionVariableStyleEnabled` 保留；
    `supportsBrushStyleControls()` 仍仅 PEN/HIGHLIGHTER。
- `note/src/main/ets/core/model/ShapeDragGeometry.ets`：注释更新为 j1k.q
  休眠证据（constrain=false 为对齐）。
- 字符串：en Variable/Fixed/Dashed/Dotted；zh 可变/固定/虚线/点线。

## 版本差异记录

- 1.0.3 `x4j`：icon-only 44×24 波形选项（Phase 1386 按此实现）。
- 1.4.2 `azm.c/u4h`：icon+label 描边卡片（本 Phase 按最新版证据实现）。
- 以 1.4.2 为准更新 fixture；1.0.3 证据仍登记在案。

## Replay

- `d02-original-brush-style-glyphs.mjs`：更新为钉 1.4.2 卡片行（34 checks）。
- `d02-original-selection-mode-toggle.mjs`：选区样式行锚点改
  `brush_style_variable`（27 checks）。
