# Phase 1012 报告 — 工具箱/编辑器状态持久化族

## 范围

Toolbox/Tray/ToolState 链、三 wells、PaperBackground、
NoteStateEntity、Preference、Quiz 写形。纯审计。

## 原版发现

- 三层 FK CASCADE：Toolbox(双选记录)→Tray(type+
  lastUsed)→ToolState(13 列含 tapePattern 等默认值)。
- wells：FavoriteColor/WidthSize(按 toolType+trayIndex)/
  RecentColor(时间线)。
- PaperBackground 8 列 + BackgroundInfo 线型默认。
- NoteStateEntity：zoom/scrollOffset/语言/缩放视图。
- `nullif(?,0)` = Room AUTOINCREMENT 占位惯例。

## Harmony 决策

等价平移。

## 产出

- 证据：`phase-1012-toolbox-persistence.md`
- Fixture：`d02-toolbox-persistence.mjs`（14/14）
- ADR-0956；全量 Replay 见本提交。
