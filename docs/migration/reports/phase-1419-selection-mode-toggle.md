# Phase 1419：选择工具 Box/Free 双模式 toggle 移植报告

- 日期：2026-10-01
- 状态：完成（Desktop Replay 27 项本 Phase 检查；`note@default` /
  clean `note@ohosTest` 构建通过）
- 证据：`docs/migration/evidence/phase-1419-selection-mode-toggle.md`
- 决策：`docs/migration/adr/ADR-1355-selection-mode-toggle.md`
- Replay：`docs/migration/replays/d02-original-selection-mode-toggle.mjs`

## 目标

修正选择工具二级配置条的移植缺陷：原版 `rnm.c` 是**两枚
`w5n.b` icon+label toggle**（[Box] [Free] 并排，各带模式图标、
标签与选中态），Harmony 此前误植为单一翻转钮（标签随当前模式
变化），缺模式各自的常驻标签与独立选中态。

## 原版证据链

| 层 | 原版类 | 语义 |
|----|--------|------|
| 宿主 | `i6n`→`iw4` | 当前工具 `kqi` 选项经 `e52.X3` 排序逐项入二级条槽位 |
| 组合 | `rnm.c` | `Row(c90 8dp)` 两枚 `w5n.b`，行内无前置文本标签 |
| Box 钮 | `w5n.b` 调用点一 | icon=`j87.H.h`=`selectbox_outline`，label=`select_box_label`("Box")，cd=`select_rect_mode`，`selected=!z2`（z2=freehand），onClick=`w5e(9)`→`FALSE` |
| Free 钮 | `w5n.b` 调用点二 | icon=`j87.H.i`=`selectfreehand_outline`，label=`select_freehand_label`("Free")，cd=`select_freehand_mode`，`selected=z2`，onClick=`w5e(10)`→`TRUE` |
| 按钮 | `w5n.b`/`vqf` | `x5n.a`（shape `t8a.F`）包 `i87.b` 图标+`d4i.b` 文本；选中 `j=nta.a.d.a` accent 底，未选 `p52.j` 中性 |

## Harmony 实现（`EditorToolbar.ets` + `ToolGlyphs.ets`）

1. `TOOL_GLYPHS` 新增 `selectbox`/`selectfreehand` 两项
   （24×24 单层 `f`，pathData 逐字提取）。
2. 新增 `@Builder SelectionModeButton(glyph,label,modeA11y,
   selected,onTap)`：`Button` 内 `Row{ToolGlyph+Text}`，
   选中 `accent` 底/`onAccent` 前景，未选 `control` 底/
   `textPrimary`，`accessibilityText(modeA11y)`，
   `toolStateLoading && photoImportLeaseActive` 双门控。
3. 模式行改 `Row({ space: 8 })`：Box 钮 `selected=
   !selectionIsFreehand` → `setSelectionIsFreehand(false)`；
   Free 钮 `selected=selectionIsFreehand` →
   `setSelectionIsFreehand(true)`。
4. 移除自造 `"Selection"` 前置文本与单钮；孤儿键
   `freehand`/`rectangle` 一并清除（`selection` 键保留——
   工具菜单与 ToolboxSettingsDialog 仍用）。

## 新增资源

| key | en | zh_CN |
|-----|----|-------|
| `select_box_label` | Box | 框选 |
| `select_freehand_label` | Free | 自由 |

## 验证

- `d02-original-selection-mode-toggle.mjs`：27/27（双钮字段
  锚定、`w5e` 9/10 布尔派发、`j87` 图标映射、`w5n.b` 选中
  accent、Harmony 结构/门控/资源/清理检查）。
- 重锚：`d02-original-ui-tools-tail.mjs`（a11y 改验
  `modeA11y` 槽位）、`d02-toolbar-direct-mutations-shared-
  ingress-lease-bound.mjs`（lease 守卫改锚 `SelectionModeButton`
  builder + 双向 setter 调用点）。
- 全量 Desktop Replay：1271/1271。
- `note@default`：BUILD SUCCESSFUL；clean `note@ohosTest`：
  BUILD SUCCESSFUL（含 `OhosTestCompileArkTS`）。
