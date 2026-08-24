# ADR-0344：编辑器初始加载销毁竞态绑定

Status: Accepted - Phase 367（2026-08-24）

## Context

`aboutToAppear()` 调用 `loadPages()` 后，`aboutToDisappear()` 可在同一轮销毁并递增 pageLoadGeneration。
原实现先递增捕获旧代数，再因旧 in-flight 直接返回，导致已销毁组件继续执行初始加载并发布 repo、标题、
pages 和背景。

## Decision

- 入口在设置 in-flight 前检查 `editorDisposed`，拒绝 dispose-before-entry 竞态。
- pages 发布后的关键门禁改为 `editorDisposed || generation mismatch`，再执行背景读取和后续发布。
- 外层失败续体保留既有 disposal/generation 拒绝；同代 finally 继续清理 loading。

## Consequences

已销毁编辑器不再启动或继续初始加载。真实设备快速打开/关闭矩阵仍属后续验收；本决策不启动模拟器、虚拟机、
真机或 Hypium。
