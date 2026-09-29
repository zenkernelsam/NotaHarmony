# Phase 1026 报告 — Preference KV + NoteStateEntity

## 范围

`Preference`/`NoteStateEntity` 写路径+分工。纯审计。

## 原版发现

- `Preference{key PK, long_value}` = app KV
  （INSERT OR REPLACE）；与 WorkManager 同名内部表
  区分。
- `NoteStateEntity{id PK, zoom REAL, scrollOffset,
  lastCodeBlockLanguage?, zoomViewSourceRect?,
  zoomViewShown?}` 6 列 = 编辑器 UI 恢复态
  （缩放+滚动+代码块语言+缩放视图矩形/可见性）。

## Harmony 决策

等价平移；编辑器恢复语义保留。

## 产出

- 证据：`phase-1026-preference-notestate.md`
- Fixture：`d02-preference-notestate.mjs`（10/10）
- ADR-0970；全量 Replay 见本提交。
