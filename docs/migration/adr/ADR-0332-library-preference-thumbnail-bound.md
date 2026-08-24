# ADR-0332：资料库偏好与缩略图生命周期绑定

Status: Accepted - Phase 355（2026-08-24）

## Context

LibraryPage 的排序切换会同步改内存、启动缩略图刷新，并通过 Preferences 异步 flush 全局排序键。可见缩略图
50ms debounce 也可能跨页面销毁触发。此前两者缺少完整生命周期门。

## Decision

- `setSortMode()` 入口要求 pageActive；销毁后的菜单迟到动作不再修改 ViewModel、启动刷新或写全局偏好。
- 可见缩略图 debounce 触发时捕获 lifecycle generation；回调必须 pageActive 且同代才允许 refreshThumbnails。
- aboutToDisappear 继续取消 thumbnail request timer，并递增 lifecycle/thumbnail generations。
- durable 排序偏好在下一次活动页加载时读取；thumbnail mutex/request generation 契约不变。

## Consequences

旧资料库实例不能在销毁边界后写入全局排序状态或调度渲染。真实设备快速返回、连续滚动和主题/排序组合矩阵
继续独立开放。
