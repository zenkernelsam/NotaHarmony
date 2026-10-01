# ADR-1355 选择工具 Box/Free 双模式 toggle（w5n.b 双钮结构）

- 状态：Accepted
- 日期：2026-10-01
- 关联 Phase：1419
- 接续：ADR-1354（最近删除选择制）；同族：ADR-0645（选区菜单裁定）
- 证据：`docs/migration/evidence/phase-1419-selection-mode-toggle.md`

## 背景

原版选择工具的二级配置项 `rnm.c`（`i6n` 二级条经 `iw4` 槽位渲染）是
**两枚 `w5n.b` icon+label toggle**：[Box]（`selectbox_outline` 图标 +
"Box" 标签 + `select_rect_mode` a11y）与 [Free]（`selectfreehand_outline`
图标 + "Free" 标签 + `select_freehand_mode` a11y），8dp 间距行，
选中态 accent 底（`nta.a.d.a`），点击分别派发 `w5e` case 9/10 →
`FALSE`/`TRUE` 置矩形/自由模式。

Harmony 此前为一枚单一 toggle 钮（标签 = 当前模式名，点击翻转）——
行为等价但偏离原版结构：缺一端的常驻可见标签、缺模式各自的
`w5n.b` 选中态，且与原版行内无前置文本标签的布局不符。

## 决策

1. **双钮结构**：`isSelectionActive` 分支首行替换为
   `Row({ space: 8 })` + `SelectionModeButton` ×2（新增 `@Builder`，
   对应 `w5n.b`）：Box → `setSelectionIsFreehand(false)`，Free →
   `setSelectionIsFreehand(true)`，各自 `selected` 位按
   `selectionIsFreehand` 取反/直取（对齐 `z3=!z2` / `z2`）。
2. **图标**：`TOOL_GLYPHS` 新增 `selectbox`/`selectfreehand`，
   pathData 逐字取自 `ui_designsystem__selectbox_outline` /
   `selectfreehand_outline`（24×24 单层填充，`j87.H.h/.i`）。
3. **文案/a11y**：新增 `select_box_label`="Box"、
   `select_freehand_label`="Free"（zh：框选/自由）；a11y 沿用
   `select_rect_mode`/`select_freehand_mode`（原版 cd 槽位）。
4. **视觉**：选中 `accent` 底 + `onAccent` 前景，非选中
   `control` 底 + `textPrimary`——Harmony `SelectionStyleButton`
   既有 accent 选中惯例，对应原版 `nta.a.d.a` 选中态。
5. **清理**：移除自造 `"Selection"` 前置文本（原版行内无标签）与
   单钮；孤儿资源键 `freehand`/`rectangle` 随单钮一并清除。
   门控沿用 `toolStateLoading && photoImportLeaseActive` 租约约定。

## 后果

- 行为等价（同一 `selectionIsFreehand` 持久位），视觉/语义与原版
  对齐：两模式各自常驻可辨，a11y 各报其模式名。
- 旧 Replay 锚点已重锚：`d02-original-ui-tools-tail.mjs`、
  `d02-toolbar-direct-mutations-shared-ingress-lease-bound.mjs`。
- 新增 `d02-original-selection-mode-toggle.mjs`（27 项）。
