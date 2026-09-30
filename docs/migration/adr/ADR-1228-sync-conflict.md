# ADR-1228：CRDT 同步冲突 + op 下载

## 状态

已接受（Phase 1284）。

## 决策

`ops/synced` 冲突异常 + `NoteOpsUpdaterWorker` →
Harmony `WorkScheduler`+`BusinessError` 分类。

## 理由

`StaleSyncedNote`(ttf)/`CorruptedSyncedOp`(ttf+uq9+
AssertionError)/`AccessDenied`(403)/`NoteOpsNotFound`(404)
= CRDT 同步冲突分类法（op 应用断言=完整性校验）；
`NoteOpsUpdaterWorker`（CoroutineWorker+noteOps/
rawMetadata/diskQuota/downloadPriority 仓库）——
op 拉取/应用工作器。

## 后果

Harmony 同步 = WorkScheduler+错误分类 —— CRDT op
应用+冲突处理语义保真。
