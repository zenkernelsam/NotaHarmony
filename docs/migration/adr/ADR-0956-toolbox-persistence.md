# ADR-0956 — 工具箱/编辑器状态持久化族

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- Toolbox→Tray→ToolState 三层 FK CASCADE；
  `trayIndex` 槽序、`mostRecently/previously`
  双选记录、`tapePattern/selectionIsFreehand/
  eraserIsPartial` 标志位（含 DEFAULT）。
- 三 wells（FavoriteColor/WidthSize/RecentColor）+
  `nullif(?,0)` 自增。
- `PaperBackground`/`BackgroundInfo` 纸面族；
  `NoteStateEntity` 每笔记视图态；`Preference` KV。

## Harmony 决策

等价平移 relationalStore；FK/默认值/槽序保留。

## Parity 状态

等价。

## 验证

- `d02-toolbox-persistence.mjs`：14/14 通过。
