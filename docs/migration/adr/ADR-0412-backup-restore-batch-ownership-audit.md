# ADR-0412: 备份恢复批量所有权审计裁决

日期：2026-08-25

## 状态

Accepted

## 背景

Phase 439 后继续窄审云恢复事务边界。`BackupBatchApplier` 采用逐笔记导入事务和倒序补偿，
需要确认批量所有权不会被并发写入绕过；同时确认导出快照门禁没有重复缺口。

## 决策

1. 云恢复、本地导入、云备份和 WebDAV 配置提交继续共用进程级 `backupOperationLease`。
   该租约是非排队所有权：第二个页面实例或并发入口 fail closed，而不是隐式排队。
2. 批量创建只通过名义化 importer adapter 进入 `NoteImporter`；补偿删除只处理本次记录的
   新身份或 importer 报告的残留身份。
3. 补偿中的 `removeImportedNote()` 重新获取权威 `NoteImporter.importMutex`；失败不中断后续
   补偿，并以 `ROLLBACK_INCOMPLETE` 显式暴露不可证明回滚的身份。
4. 导出在最终库快照复核前检查编辑保存队列终态；`assertStableBackupSnapshot()` 对集合规模
   与逐笔记标题、时间、revision 漂移 fail closed。该门禁已有独立 Replay 和 ArkTS 测试，
   不重复实现。

## 结果

未发现新的生产缺陷；Phase 440 保持文档与 Replay 证据闭环，不改写已验证的事务边界。
