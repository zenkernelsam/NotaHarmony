# ADR-0148: BackupBatchRestorer 输入边界

## 决策

`BackupBatchRestorer.fetch` 在任何远端下载前，将传入 manifest 序列化并通过 `parseBackupBatch` 重新校验；结构、身份或预算不合法时直接抛错。

## 原因

恢复器是独立数据层 API，不能假设所有调用方都经过设置页的解析路径。边界层重复校验可防止未来调用方直接构造非法 manifest。

## 验收

静态 replay 检查校验发生在 download 循环之前；真实服务端恢复仍需后续验收。
