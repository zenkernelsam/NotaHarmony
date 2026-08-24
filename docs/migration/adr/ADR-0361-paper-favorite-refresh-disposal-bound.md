# ADR-0361：纸张收藏刷新销毁绑定

Status: Accepted - Phase 384（2026-08-24）

## Context

`PageSettingsPanel.toggleFavorite()` 在收藏写入后已有销毁检查，但随后把
`await store.listFavorites()` 的结果直接赋给 `favorites`。若面板在刷新 await 期间关闭，迟到结果仍会写入旧组件状态。

## Decision

- 先用局部变量接收 `listFavorites()` 结果。
- 结果返回后再次检查 `panelDisposed`；陈旧续体不发布收藏列表。
- 活动面板的收藏切换、权威刷新和 finally 忙碌清理语义不变。

## Consequences

关闭后的旧面板不会再收到迟到的收藏刷新。真实 SQLite 时序与快速关闭矩阵仍需后续设备级验收；本决策不启动
模拟器、虚拟机、真机或 Hypium。