# ADR-0347：工具设置失败销毁绑定

Status: Accepted - Phase 370（2026-08-24）

## Context

`NotePage.loadPages()` 注册的工具设置持久化失败回调先记录日志，然后无条件弹 toast。
离开或重建编辑器后的迟到失败仍可向旧 NotePage 显示“Tool settings could not be saved”。

## Decision

- 回调在诊断日志后、toast 前检查 `editorDisposed`；销毁态直接返回，不触达旧 UI。
- 错误日志保留，便于追踪 durable 工具与设置保存结果。
- `EditorViewModel` 的持久化错误发布契约和未销毁时的用户提示语义不变。

## Consequences

旧 NotePage 不再显示迟到的工具设置保存失败。真实设备快速退出矩阵仍属后续验收；本决策不启动模拟器、
虚拟机、真机或 Hypium。
