# Phase 1297 证据 — core/ 基础设施（日志/性能/网络/异常）

来源：`core/{analytics,common/logging,network,retrofit,
model}/*.java`。

## `NbPerformance` = 性能追踪（SpanAborted）

`NbPerformance$SpanAborted extends Exception` —— 性能
span 中止（启动/同步/渲染指标追踪）。

## `NbLog` = 日志门面

`NbLog$FatalLogError extends Error` —— 日志门面 +
fatal 日志抛 Error（assert-fatal 行为）。

## `core/network` = 网络异常

`NoConnectivityException extends IOException`
("No network connectivity") + `NotAuthenticatedException`
+ `HttpStatusException` —— 连接性/认证/HTTP 状态错误。

## `core/retrofit` = `HttpFailureException{int status,
String message}` —— Retrofit REST 失败。

## `core/model/CopyPasteException` = 复制/粘贴 CRDT 异常

sealed `CopyPasteException extends Exception`：
```
ConcurrentPaste      // 并发粘贴冲突
Consistency          // 一致性校验失败
...                  // （更多子类）
```

→ 文档复制/粘贴的 CRDT 一致性错误分类法。

## 语义

**核心基础设施** —— 性能 span+日志门面+网络/REST
错误+复制粘贴 CRDT 冲突异常 —— 横切关注点层。

## Harmony 决策

日志/性能 → `hilog`+`HiTrace`/`hiAppEvent`；网络异常 →
`BusinessError`；CopyPasteException → Harmony CRDT 一致
性错误类 —— 基础设施语义保真。

## 产出

- fixture `d02-core-infra.mjs`（10 断言）。
- ADR-1241；中文报告。
