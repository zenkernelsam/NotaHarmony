# ADR-0346：页面操作失败销毁绑定

Status: Accepted - Phase 369（2026-08-24）

## Context

页面操作成功路径已有 disposal 守卫，但 `runPageOperation()` 的 catch 在记录日志后无条件弹失败 toast。
离开或重建编辑器后的迟到异常仍会向旧 NotePage 显示“页面操作失败”。

## Decision

- 失败续体记录诊断后、弹提示前检查 `editorDisposed`；销毁态直接返回。
- 错误日志保留，便于追踪 durable 操作结果；`finally` 继续权威清理 pageOperationBusy。
- 各操作的数据库失败语义和成功发布契约不变。

## Consequences

旧 NotePage 不再显示迟到页面操作失败。真实设备快速增删页矩阵仍属后续验收；本决策不启动模拟器、虚拟机、
真机或 Hypium。
