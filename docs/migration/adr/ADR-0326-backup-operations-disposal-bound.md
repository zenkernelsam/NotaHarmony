# ADR-0326：备份页长事务销毁绑定

Status: Accepted - Phase 349（2026-08-24）

## Context

BackupPage 的本地导出、本地导入、云端备份和云端恢复都是跨越文件系统、数据库或网络的长事务。此前页面没有
`aboutToDisappear()`；操作期间返回后，迟到续体仍可修改 `hasLastBackup` 等状态并弹出对话框或 toast。

## Decision

- 页面销毁时设置 `pageDisposed`，加载路径在发布前检查。
- 四个操作开始时递增 operation lifecycle generation；每个关键 await 后校验销毁态与同代身份。
- 过期成功或失败直接进入既有 `finally`，释放共享租约并复位 busy/status，但不发布 UI 结果。
- durable 备份、恢复与上次备份时间保持权威；下一次页面加载继续读取持久层。

## Consequences

UI 不能被已离开页面的迟到事务打扰。真实 WebDAV 服务器矩阵、失败注入和设备级恢复验收继续独立开放。
