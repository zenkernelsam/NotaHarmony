# Phase 1468 报告：方向键微移选区（ntf/otf 通道）

## 原版行为（1.4.2 证据）

键盘兜底链 `f2.java:285-325`：纯 DPAD 方向键（`bd8.j0`=
{DPAD_UP/DOWN/LEFT/RIGHT}、无 ctrl/alt/shift、非文本编辑）——

- **DOWN**：有活跃选区且 `u7b.g` 键盘模式（默认 true）→
  `guf.g.p(ntf(±bd8.l0=2.0 文档单位, isRepeat))` 微移选区；
  无选区或模式关 → `mfc.s` 视口滚动 10% 视口尺寸。
- **UP**：`guf.g.p(otf.a)` NudgeEnd → `guf.u` 单事务提交。
- **触摸分发落空**（`ms1:784`）同推 `otf.a`——触摸终结微移。
- `guf.t` 步进语义：xtf 式会话累加位移、按步应用平移 op、
  选区偏移即时更新；isRepeat 无在飞会话时忽略。
- `guf.x` 提交门：`r9a.k()==0` 零位移不产事务。

## Harmony 缺口

方向键未接管——无微移、无滚动降级。

## 实现

- `OriginalKeyboardChords`：`ORIGIN_KEYCODE_DPAD_*=2012..2015`
  + `NUDGE_STEP=2.0` + `SCROLL_FRACTION=0.1`。
- `onCanvasKeyEvent`（`!textEditing` 块内）：纯方向键 DOWN →
  `onSelectionNudgeKeyDown`（选区支 `moveSelected(±2.0)`+快照基线
  重建 / 滚动支 `setScroll(±10%视口)`）；UP →
  `endSelectionNudgeCommit`。
- `onTouchDown` 顶部：挂起微移先提交（ms1:784 等价）。
- `applySelectionTransform` 基线源增 `selectionNudgeActive`。

## 验证

- 新 fixture `d02-original-selection-nudge.mjs`：18 项（常量 pin、
  分发结构、双支、提交门、可执行累积模型——含抵消零位移不提交）。
- 键盘族 fixture（keymap/shortcuts/kbd-chords 等 6 件）无回归。
- `note@default` 构建通过；全量基线与 `note@ohosTest` 收尾验证。

## 遗留差异

- `u7b.g` 键盘光标模式降级支（选区存在但模式关→滚动）未复刻，
  按默认 true 等价；越页微移 fail-closed 同 P1459。
