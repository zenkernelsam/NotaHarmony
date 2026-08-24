# ADR-0333：资料库主题切换生命周期绑定

Status: Accepted - Phase 356（2026-08-24）

## Context

LibraryPage 主题菜单的 `setThemeMode()` 会同步写入进程全局 AppStorage、启动缩略图刷新，并通过 Preferences
异步持久化主题键。此前入口没有 pageActive 门禁；页面销毁后的迟到菜单动作仍能改变当前应用主题、进入渲染
管线并写 durable 偏好。

## Decision

- `setThemeMode()` 首个可执行语句检查 pageActive；非活动页直接返回。
- 因此同步主题发布、thumbnail request generation、Preferences get/put/flush 与失败日志都不会被旧页动作触发。
- 排序、搜索、文件夹选择与可见缩略图 debounce 的既有 lifecycle/request/generation 契约保持不变。

## Consequences

旧 LibraryPage 实例不能跨销毁边界修改全局主题或持久状态。durable theme mode 继续由下一次活动页权威读取；
真实设备快速返回、系统深浅色变化与主题/缩略图矩阵仍属后续验收范围。
