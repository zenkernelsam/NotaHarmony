# ADR-0360：WebDAV 保存反馈换代绑定

Status: Accepted - Phase 383（2026-08-24）

## Context

WebDAV 设置页 `saveConfigOnce()` 在异步确认、持久化和异常续体中复用 `safeToast()`。该方法只检查
`pageDisposed`，不比较捕获的 `lifecycleGeneration`。页面被替换但尚未销毁时，迟到保存成功或失败仍可向旧页
发布 toast。

## Decision

- `safeToast(message, expectedLifecycleGeneration?)` 改为统一调用 `isDisposed()`；未传代次的既有同步提示保持
  当前代次语义。
- 保存持久化返回后的成功、cleanup-pending、提交失败，以及外层请求失败 toast 都显式传入捕获的
  `lifecycleGeneration`。
- 陈旧任务静默返回；活动页的保存反馈和 finally 租约释放语义不变。

## Consequences

旧设置页实例不再收到替换后迟到的保存结果。真实快速导航、多窗口和系统对话框时序仍需后续设备级验收。本决策
不启动模拟器、虚拟机、真机或 Hypium。