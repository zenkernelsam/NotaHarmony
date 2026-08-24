# ADR-0337：剪贴板探测生命周期绑定

Status: Accepted - Phase 360（2026-08-24）

## Context

`refreshSystemClipboardImageAvailability()` 的异步 probe 已有 probe generation，但其公共前置函数
`canProbeOriginalClipboardImage()` 只检查 loaded/loading/history/persistence，不检查 `lifecycleActive`。
销毁后迟到的系统剪贴板变更仍可触发新 probe，并在 await 后把 `systemClipboardImageAvailable` 发布到旧
编辑器实例。

## Decision

- `canProbeOriginalClipboardImage()` 首项增加 `lifecycleActive`，使入口同步探测和异步成功续体共用同一
 生命周期门禁。
- 保留既有 probe generation、page context、history busy 和 persistence 契约；不改变剪贴板图片插入行为。
- 销毁后的迟到结果直接拒绝，不写旧 UI 状态。

## Consequences

旧 NoteCanvasView 不能跨销毁边界发布剪贴板可用性。真实设备快速粘贴、跨应用剪贴板变更与返回矩阵仍属
后续验收；本决策不启动设备或 Hypium。
