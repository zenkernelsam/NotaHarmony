# ADR-1253：CRDT 线格式保真

## 状态

已接受（Phase 1309）。

## 决策

Harmony CRDT 保真原版 FlatBuffer 线格式 + `exc.A0`
排序比较器 + 64-bit packing + site-ID 互斥同步 —
— 与原版同步互操作；本地 op 扩展分层叠加。

## 理由

`OperationIdentity`（timestamp+siteId 64-bit pack +
`compareOriginalSequenceIdentity`=exc.A0 signed-int/
unsigned-site 逐位复刻）+ `OriginalSyncedOperation
FlatBuffer`/`EnvelopeEncoder`（读写原版 FlatBuffer
信封）+ `IncomingOperationSyncCoordinator`（AsyncMutex
+deferred-bundle 重放+site-ID）—— CRDT 线格式+
排序+同步语义与原版一致。

## 后果

Harmony 同步与原版线格式互操作；本地 op 超集为
增量 —— CRDT 互通性保真（修正 Phase 1308：线格式
保真，仅本地分类法有差异）。
