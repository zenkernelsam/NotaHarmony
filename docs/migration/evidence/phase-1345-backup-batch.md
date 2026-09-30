# Phase 1345 证据 — 备份批内部 + 富文本编码

来源：`data/{BackupBatchPublisher,BackupBatchRestorer,
BackupBatchSpec,OriginalRichTextStylePayloadEncoder}.ets`。

## `BackupBatch*` = WebDAV 批格式 + 发布回读校验

```
BackupBatchSpec: BACKUP_BATCH_FORMAT='nota.backup-batch'
  + isValidBackupBatchId
BackupBatchPublisher.publish(packages, batchId, completedAt):
  校验 batchId+timestamp
  ensureBackupBatchDir → backupBatchObjectUrl 逐对象上传
  serializeBackupBatch → manifest → backupBatchManifestUrl
  **回读校验**：下载 manifest + CryptoBackupBatchHasher
    比对 hash —— 不一致即失败（publish-verify 往返）
BackupBatchRestorer —— 按 batchObjectUrl 逐项恢复
```

→ WebDAV 批备份 = `nota.backup-batch` 格式 + 上传 +
**发布回读 hash 校验**（防传输损坏）+ 逐项恢复。

## `OriginalRichTextStylePayloadEncoder`

富文本样式 op payload 编码（characterStyleRuns→FlatBuffer
op 载荷，对照 `haa` SET_STYLE）。

## Harmony 决策

备份 = `nota.backup-batch` 批格式+发布回读 hash 校验+
逐项恢复 —— 对照原版备份批次；富文本样式 op 编码保真。

## 产出

- fixture `d02-backup-batch.mjs`（10 断言）。
- ADR-1287；中文报告。
