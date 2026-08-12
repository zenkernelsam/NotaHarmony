# ADR-0154: 系统 Backup manifest 数值边界

## 决策

系统 Backup Ability 的 manifest `createdAt` 必须是正安全整数；每个文件条目的 `size` 必须是非负安全整数。备份创建使用 `Date.now()`，恢复校验拒绝其它数值。

## 原因

系统备份与 WebDAV 批次是两套独立实现。系统路径此前仅检查 `Number.isFinite`，可接受小数或超出安全整数的大小/时间，造成恢复进度和预算计算不稳定。两条链应保持同样的 JavaScript 数值安全边界。

## 验收

静态 replay 检查 manifest 时间与条目大小均使用 `Number.isSafeInteger`，且恢复在复制前完成校验。
