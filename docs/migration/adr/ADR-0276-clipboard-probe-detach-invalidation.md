# ADR-0276: Clipboard Probe Invalidation on Detach

日期：2026-08-23（Asia/Shanghai）
状态：Accepted

## Context

Phase 297 用 probe generation 防止连续刷新的迟到结果覆盖新状态，但 `aboutToDisappear()` 的退订路径只
清空 listener 和可见性状态。若一个 probe 已经启动且页面数据仍满足就绪条件，其迟到 promise 仍可能在组件
销毁后回写。

## Decision

`stopSystemClipboardImageAvailabilityUpdates()` 在 finally 中除移除 listener、清空可用性状态外，同时递增
`systemClipboardImageProbeGeneration`。组件退订后所有已启动 probe 立即过期；后续重新挂载会从新代数开始。
MIME exact match、fail closed 与点击后的 READ_PASTEBOARD 契约不变。
