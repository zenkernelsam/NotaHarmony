# Phase 1316 报告 — 导出 + WebDAV 备份

## 完成内容

- `NoteExporter`（`.note` iOS ZIP 导出+录音并入 assets
  +`BackupSnapshotGuard` 快照一致性+picker）+ **WebDAV
  自动备份**（`WebDAVClient`/`ConfigStore`/`Config
  Transaction`+`BackupBatch{Applier,Publisher,Restorer,
  Spec}`+`BackupHash`/`BackupOperationLease`/`Snapshot
  Guard`+`NoteBackupAbility`+`BackupPage`/`WebDAVSettings
  Page` UI）—— 导出+自动备份层（原版 auto-backup
  provider → Harmony WebDAV）。

## 产出

- evidence `phase-1316-export-backup.md`
- fixture `d02-export-backup.mjs`（10/10）
- ADR-1260
