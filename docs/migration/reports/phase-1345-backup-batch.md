# Phase 1345 报告 — 备份批内部

## 完成内容

- `BackupBatchSpec`（`nota.backup-batch` 格式+batchId
  校验）；`BackupBatchPublisher`（逐对象上传+manifest+
  **发布回读 hash 校验**——下载回比对，不一致即失败）；
  `BackupBatchRestorer` 逐项恢复；`OriginalRichTextStyle
  PayloadEncoder` —— 备份完整性+样式编码保真。
- `data/` 层逐文件审计**清零**（无未审计文件）。

## 产出

- evidence `phase-1345-backup-batch.md`
- fixture `d02-backup-batch.mjs`（10/10）
- ADR-1287
