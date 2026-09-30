# Phase 1284 报告 — CRDT 同步冲突 + op 下载

## 完成内容

- `ops/synced` 冲突异常：`StaleSyncedNote`(ttf 元数据
  过期)/`CorruptedSyncedOp`(ttf+uq9+AssertionError op
  应用断言)/`AccessDenied`(403)/`NoteOpsNotFound`(404)/
  `NoteHasNoOps`；`NoteOpsUpdaterWorker`（CoroutineWorker
  +noteOpsRepository/rawNoteMetadata/diskQuota/
  opsDownloadPriority）—— CRDT op 拉取/应用/冲突处理。

## 产出

- evidence `phase-1284-sync-conflict.md`
- fixture `d02-sync-conflict.mjs`（10/10）
- ADR-1228
