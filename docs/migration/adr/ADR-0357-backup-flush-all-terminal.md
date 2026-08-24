# ADR-0357：备份排空失败队列终止化

Status: Accepted - Phase 380（2026-08-24）

## Context

WebDAV 整库导出前调用 `StrokePersistence.flushAll()`。但 `LatestWriteQueue` 的失败语义要求把失败快照保留为 dirty，等待用户重试；旧 `flushAll()` 又用 `while (true)` 反复收集并 flush 这些队列。一次持久化失败会把 WebDAV 备份卡在无限重试循环中。

## Decision

- `flushAll()` 改为一次性快照当前 dirty 队列并逐个 `flush()`；任一失败立即向导出准备层抛出。
- 失败队列继续由 `LatestWriteQueue` 保留，供编辑器下一次显式保存重试。
- 成功队列照常注销；NoteExporter 继续用 `hasPendingSaves()` 和入队 generation 拦截未完成状态。
- 不改变单页保存、切页排空和用户动作边界的既有行为。

## Consequences

备份准备遇到失败保存会快速进入本地“快照变化/准备失败”提示，不再永久阻塞。该决策只保证进程内排空尝试的有限性；真实磁盘故障与跨进程并发仍需设备级故障注入验收。本决策不启动模拟器、虚拟机、真机或 Hypium。
