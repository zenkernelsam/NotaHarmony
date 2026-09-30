# ADR-1287：备份批内部

## 状态

已接受（Phase 1345）。

## 决策

WebDAV 备份 = `nota.backup-batch` 批格式 + 上传 +
**发布回读 hash 校验** + 逐项恢复 —— 对照原版批次。

## 理由

`BackupBatchSpec`（`nota.backup-batch` 格式+batchId 校验）；
`BackupBatchPublisher`（逐对象上传+manifest 序列化+
**回读校验**：下载 manifest+`CryptoBackupBatchHasher`
比对 hash，不一致即失败）；`BackupBatchRestorer` 逐项
恢复；`OriginalRichTextStylePayloadEncoder` 样式 op 编码。

## 后果

备份发布含回读校验（防传输损坏）—— 备份完整性保真。
