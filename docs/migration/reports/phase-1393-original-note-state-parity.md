# Phase 1393 报告 — `note_state` 补齐 `NoteStateEntity` 全列

- 阶段：1393
- ADR：ADR-1329
- 证据：`docs/migration/evidence/phase-1393-original-note-state-parity.md`
- Replay：`docs/migration/replays/d02-original-note-state-parity.mjs`（27 检查）

## 背景

延续 Phase 1391/1392 的 Room schema 逐表比对。`note_state` 对
`NoteStateEntity`（`ca3.java:519`，8 列）尚缺三列：`zoomViewSourceRect`、
`zoomViewShown`、`isTextOnly`。本 Phase 补齐，使导入的原版 note_state 行
round-trip 不丢列。

## 修复

- **schema**：migration 75 增 `zoom_view_source_rect TEXT`/`zoom_view_shown
  INTEGER`/`is_text_only INTEGER`（`DEFAULT NULL`）；DDL 同步；
  `DB_VERSION 74→75`。
- **持久化**：`NoteViewState` 增三可选字段；`getViewState` 读；
  `saveViewState` 重构 `readPreservedNoteState`——`ON_CONFLICT_REPLACE`
  整行重写前，4 个保留列 `undefined`→读现值（viewport 保存不误清导入值），
  布尔列写 INTEGER 0/1。

## 逐列行为判定

- `zoom_view_source_rect`/`zoom_view_shown`：原版持久化放大窗矩形+显隐、
  reopen 恢复。Harmony 放大窗 tool-gated（isShown=工具激活、锚定末笔/视口），
  模型不同——**保列**，不强切恢复语义。
- `is_text_only`：原版 Text-only 视图模式（隐藏非文本元素+banner+auto-exit）
  ——独立 Phase（渲染管线）。**保列**。

## 改动文件

- `note/src/main/ets/data/DatabaseHelper.ets` — DB_VERSION=75、note_state DDL、migration 75
- `note/src/main/ets/core/model/NoteTypes.ets` — `NoteViewState` 三字段
- `note/src/main/ets/data/NoteRepositoryImpl.ets` — getViewState 读、saveViewState
  readPreservedNoteState/pick/boolToInt 保留写
- `note/src/test/DatabaseHelper.test.ets` — `assertEqual(75)`
- `docs/migration/replays/d02-original-note-state-parity.mjs`（新增）
- 版本钉线 fixtures `DB_VERSION=74→75`

## 验收

- 硬证据：`ca3.java:519`、`chb.java:44-47`、`wmb.java:75/102`、
  `xf3.java:103`、`sbe.java`/`ten.java`（序列化）。
- `d02-original-note-state-parity` 27 检查绿；全量基线全绿。
- `note@default`/`note@ohosTest` HAP 构建成功，无新增 ArkTS 错误。

## fail-closed / 边界

`zoomView*`/`isTextOnly` 为 round-trip 完整性保列，Harmony 行为接入留待
放大窗持久化恢复 / text-only 渲染模式两个后续 Phase。
