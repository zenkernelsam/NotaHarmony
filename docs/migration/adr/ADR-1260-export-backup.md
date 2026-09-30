# ADR-1260：导出 + WebDAV 备份

## 状态

已接受（Phase 1316）。

## 决策

`.note` 导出保真（iOS ZIP+快照守卫）；自动备份 =
WebDAV 客户端（原版多 provider → Harmony WebDAV）。

## 理由

`NoteExporter`（`.note`+录音并入 assets+`BackupSnapshot
Guard` 一致性+picker）+ WebDAV 备份栈（`WebDAVClient`/
`ConfigStore`/`ConfigTransaction`+`BackupBatch{Applier,
Publisher,Restorer}`+`BackupHash`/`OperationLease`/
`SnapshotGuard`+`NoteBackupAbility`+设置 UI）—— 导出
+自动备份层。

## 后果

`.note` 导出保真；备份走 WebDAV（原版 provider 集合
的 Harmony 等价物）—— 备份/导出语义保真。
