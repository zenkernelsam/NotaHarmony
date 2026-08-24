# ADR-0352：备份失败销毁绑定

Status: Accepted - Phase 375（2026-08-24）

## Context

本地导出、导入、WebDAV 备份与云端恢复的成功续体已有 `isStale` 门禁，但外层 catch 记录错误后无条件弹出失败
对话框；离开或重建 BackupPage 后的迟到异常仍可触达旧 UI。

## Decision

- 四个异步操作的外层 catch 复用现有 `isStale(lifecycleGeneration)` 联合校验；销毁或换代时只保留错误日志并返回。
- 活动页失败提示语义不变；finally 继续权威清理 busy、statusText 和全局 backup lease。

## Consequences

旧 BackupPage 不再显示迟到的导出、导入、备份或恢复失败对话框。真实设备网络中断矩阵仍属后续验收；本决策不启动模拟器、虚拟机、真机或 Hypium。
