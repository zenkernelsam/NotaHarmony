# ADR-0147: Backup publisher manifest 预校验

## 决策

`BackupBatchPublisher.publish` 在任何远端目录或对象上传前校验 `batchId`、`completedAt`、条目 noteId、revision、updatedAt 及非空数据，并复用 manifest 的批次 ID 合法性规则。

## 原因

发布器若接受非法字段，会上传一个随后无法通过 `parseBackupBatch` 验证的 manifest，造成“备份成功但不可恢复”。预校验还避免产生孤立远端对象。

## 验收

静态 replay 检查所有字段校验位于 `ensureBackupDir` 前；真实 WebDAV 上传失败仍需服务端验收。
