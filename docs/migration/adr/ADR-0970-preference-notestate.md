# ADR-0970 — Preference KV + NoteStateEntity

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `Preference{key PK, long_value}` = app 键值表
  （INSERT OR REPLACE；与 WorkManager 同名内部表
  不同）。
- `NoteStateEntity{id PK, zoom REAL, scrollOffset,
  lastCodeBlockLanguage?, zoomViewSourceRect?,
  zoomViewShown?}` = per-note 编辑器 UI 态（6 列）。

## Harmony 决策

平移；NoteStateEntity 的 zoom/scroll/rect 编辑器
恢复语义保留；Preference 仅 long。

## Parity 状态

等价。

## 验证

- `d02-preference-notestate.mjs`：10/10 通过。
