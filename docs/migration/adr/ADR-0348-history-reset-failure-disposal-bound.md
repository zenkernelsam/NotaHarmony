# ADR-0348：历史重置失败销毁绑定

Status: Accepted - Phase 371（2026-08-24）

## Context

持久历史重置的成功续体已有 `lifecycleActive` 门禁，但 catch 在记录失败后无条件调用恢复提示；用户确认重置后立即离开编辑器时，迟到异常仍可向已销毁 Canvas 弹出“history recovery failed”。

## Decision

- 失败续体在错误日志后、提示前检查 `lifecycleActive`；销毁态直接返回，不触达旧 UI。
- durable 重置失败诊断保留；`finally` 继续权威清理 historyBusy 与 historyRecoveryBusy。
- 活动编辑器的成功、失败提示和数据库语义不变。

## Consequences

旧 NoteCanvasView 不再显示迟到的历史重置失败。真实设备快速退出矩阵仍属后续验收；本决策不启动模拟器、虚拟机、真机或 Hypium。
