# Phase 1297 报告 — 核心基础设施

## 完成内容

- `NbPerformance`（SpanAborted 性能 span）；`NbLog`（日志
  门面+FatalLogError）；`NoConnectivity`/`NotAuthenticated`
  /`HttpStatusException`（网络异常）；`HttpFailure
  Exception{status,msg}`（Retrofit）；`CopyPaste
  Exception`（sealed：ConcurrentPaste/Consistency =
  复制粘贴 CRDT 冲突）—— 横切关注点基础设施层。

## 产出

- evidence `phase-1297-core-infra.md`
- fixture `d02-core-infra.mjs`（10/10）
- ADR-1241
