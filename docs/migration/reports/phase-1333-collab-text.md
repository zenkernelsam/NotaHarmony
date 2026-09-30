# Phase 1333 报告 — 协作文本 op

## 完成内容

- `OriginalLocalTextMutation` = 逐字符 CRDT：
  `StoredCharacter{identity,visible}`，remove→
  `visible=false`（墓碑）、revive→`true`、insert→
  `predictOriginalTextInsertionIdentity`；`previewMutation`
  模拟→计划 —— 对照 `haa` INSERT/REMOVE/REVIVE_CHARS
  （墓碑支持并发编辑+撤销复活）；
  `PageOperationApplier`+`RichTextStyle` 配套。

## 产出

- evidence `phase-1333-collab-text.md`
- fixture `d02-collab-text.mjs`（10/10）
- ADR-1276
