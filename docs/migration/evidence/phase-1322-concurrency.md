# Phase 1322 证据 — 并发原语层

来源：`data/{AsyncMutex,DatabaseWriteMutex,LatestWrite
Queue,EditorPersistenceMutex,BackupOperationLease,Synced
OperationInbox}.ets`。

## 互斥/队列原语

```
AsyncMutex            异步互斥锁（lock→release）
DatabaseWriteMutex    DB 写互斥（域锁先于它，如
                      assetMutationMutex）
EditorPersistenceMutex  编辑器持久化互斥
LibraryMetadataMutationMutex  库元数据互斥
LatestWriteQueue<T>   单写者队列——普通快照合并、
                      用户动作边界保持 FIFO
BackupOperationLease  进程级非排队租约（备份工作流；
                      第二实例失败；跨进程靠
                      BackupExtensionAbility）
```

## `SyncedOperationInbox` = 同步 op 收件箱

`validateIncomingSyncedBatch`+`compareIncomingSynced
OperationOrder`（序比较器）+`SyncedOperationInboxStore`
→`editorPersistenceMutex.runExclusive` 下接收入站 op —
— 验证+排序+互斥应用。

## 语义

并发 = **分层互斥**（AsyncMutex+域互斥）+**写合并
队列**（LatestWriteQueue 快照合并/FIFO 边界）+**进程
租约**（BackupOperationLease）+**同步收件箱**（验证/
排序/互斥应用）—— 原版 coroutine Mutex/Channel 的
Harmony 实现。

## Harmony 决策

原版 Kotlin Mutex/Channel/worker → `AsyncMutex`+域互斥
+`LatestWriteQueue`+`BackupOperationLease` —— 并发
语义保真。

## 产出

- fixture `d02-concurrency.mjs`（10 断言）。
- ADR-1266；中文报告。
