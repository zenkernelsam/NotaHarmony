# ADR-0343：视口保存生命周期绑定

Status: Accepted - Phase 366（2026-08-24）

## Context

视口保存使用 500ms 防抖。组件销毁会取消 pending timer，但销毁前已触发回调的竞态仍可进入
`saveViewportState()`；该函数没有 lifecycle/generation 门禁，迟到续体会初始化数据库并把旧 viewport 写入
全局 note_state。

## Decision

- 防抖入口捕获触发时 `pageLoadGeneration` 并传给保存函数。
- `saveViewportState()` 在数据库初始化与写入前要求 `lifecycleActive` 且同代。
- 直接退出路径不传 generation，仅受 lifecycle 门禁保护；错误日志语义不变。

## Consequences

销毁或换代后的防抖保存不再覆盖较新编辑器视口。真实设备快速缩放、切页和返回矩阵仍属后续验收；本决策
不启动模拟器、虚拟机、真机或 Hypium。
