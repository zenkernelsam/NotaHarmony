# ADR-1266：并发原语层

## 状态

已接受（Phase 1322）。

## 决策

Kotlin Mutex/Channel/worker → `AsyncMutex`+域互斥+
`LatestWriteQueue`（快照合并/FIFO）+`BackupOperation
Lease`（跨进程租约）+`SyncedOperationInbox`（验证/
排序/互斥接收）—— 并发语义保真。

## 理由

分层互斥（AsyncMutex+DatabaseWrite/EditorPersistence/
LibraryMetadata 域锁）+写合并队列+进程租约+同步收件箱
—— 原版 coroutine 并发模型的 Harmony 实现。

## 后果

并发控制保真（互斥/合并/租约/有序接收）—— 数据
一致性语义保真。
