# ADR-1241：核心基础设施（日志/性能/网络/异常）

## 状态

已接受（Phase 1297）。

## 决策

日志/性能 → `hilog`+`HiTrace`；网络异常 →
`BusinessError`；`CopyPasteException` CRDT 冲突 →
Harmony 一致性错误类。

## 理由

`NbPerformance`(span 追踪)+`NbLog`(fatal 抛 Error)+
`NoConnectivity`/`NotAuthenticated`/`HttpStatus`+`Http
Failure`+`CopyPasteException`(ConcurrentPaste/Consistency
sealed) —— 横切关注点基础设施。

## 后果

Harmony 基础设施 = hilog+HiTrace+BusinessError+CRDT
一致性异常 —— 基础设施语义保真。
