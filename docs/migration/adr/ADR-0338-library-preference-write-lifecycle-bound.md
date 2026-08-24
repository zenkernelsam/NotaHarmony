# ADR-0338：资料库偏好写入生命周期绑定

Status: Accepted - Phase 361（2026-08-24）

## Context

排序和主题切换在入口检查 pageActive 后启动 `preferences.getPreferences()`。该 await 的迟到成功此前直接
`putSync` 并 flush，可在旧 LibraryPage 销毁或被新一代实例替换后覆盖 durable 偏好，使下一次应用启动读取
过期排序或主题。

## Decision

- 两个入口捕获触发时 lifecycle generation。
- `getPreferences()` 成功后、任何 put/flush 前联合校验 `pageActive` 与同代生命周期。
- 过期续体不写 Preferences；失败日志与既有同步内存发布保持不变。

## Consequences

旧页不能跨销毁边界改写全局偏好。durable 值继续由下一次活动页权威读取。真实设备快速切换、销毁重建与
系统主题矩阵仍属后续验收；本决策不启动设备或 Hypium。
