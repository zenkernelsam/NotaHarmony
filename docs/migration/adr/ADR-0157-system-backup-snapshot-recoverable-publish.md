# ADR-0157: 系统 Backup 快照可恢复发布

## 决策

系统 Backup 生成 staging 快照后，不直接删除现有 snapshot。旧快照先重命名为 `nota-snapshot.previous`，再尝试发布 staging；发布失败时恢复 previous，成功后才清理 previous。

## 原因

原实现先删除旧快照再重命名 staging。文件系统重命名或权限失败会同时破坏旧的可恢复备份和新批次。交换式发布把失败窗口限制为 staging，不丢失上一份成功快照。

## 验收

静态 replay 检查 previous 暂存、发布失败恢复和成功后清理顺序。真实 CoreFileKit 文件系统故障注入仍需设备测试。
