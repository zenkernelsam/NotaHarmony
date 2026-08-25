# Harmony 证据 — 备份恢复批量所有权边界

- 文件：`note/src/main/ets/ui/settings/BackupPage.ets`、
  `note/src/main/ets/data/BackupBatchApplier.ets`、
  `note/src/main/ets/data/NoteImporter.ets`、
  `note/src/main/ets/data/NoteExporter.ets`
- 现场状态：Phase 439 后补审恢复批量事务；重点核对批量导入者与补偿删除者的所有权。
- 所有权链：`restoreFromCloud()` 先取得 `backupOperationLease`；本地导入、云备份和 WebDAV
  配置提交也使用同一非排队租约，避免两个页面实例交叉执行批量变更。
- 事务链：每个备份对象由 `importFromData()` 在 importer 内部事务提交；成功/PARTIAL 必须返回
  全新非空 note ID，后续硬失败按倒序调用 `removeImportedNote()` 补偿。
- 清理链：补偿删除重新获取 `NoteImporter.importMutex`；单个删除失败继续处理剩余身份，最终以
  `ROLLBACK_INCOMPLETE` 报告残留数量与 ID。
- 相邻裁决：`exportAllNotes()` 的 flush/save-generation、逐笔记 revision 前后检查、终态二次检查
  与整库 snapshot 复核共同拒绝跨时刻拼接批次；已有 `d02-backup-library-snapshot.mjs` 覆盖。
- 结论：无新生产缺陷，不引入代码改动；新增所有权专项 Replay 锁定当前架构语义。
