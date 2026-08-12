# ADR-0159：系统 Backup 失败时清理 staging

## 决策

系统 Backup 在收集、复制或 manifest 写入任一步失败时，删除本次未发布的
`nota-snapshot.staging`，并将进度状态标记为 `failed` 后重新抛出原错误。

## 原因

staging 是未完成批次，不具备可恢复性。失败后保留它会留下过期文件并混淆下一次
备份状态；清理 staging 不影响已发布的 `nota-snapshot`，而发布阶段已有 previous
回滚保护。

## 边界

清理失败不会覆盖原始备份错误；真实 CoreFileKit 文件系统故障和进程中断仍需设备
fault injection 验收。
