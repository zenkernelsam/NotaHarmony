# ADR-0153: 备份 manifest 时间戳完整性

## 决策

备份批次 `createdAt` 和每个条目的 `updatedAt` 必须是正的 JavaScript 安全整数。发布器在远端写入前采用同一约束，解析器拒绝小数、NaN、无穷和超出安全整数范围的时间戳。

## 原因

时间戳参与最新批次选择、笔记 revision 对齐和恢复提示。只检查 `Number.isFinite` 会接受小数及超过安全整数范围的值，导致排序和 JSON 往返后语义不稳定。

## 验收

静态 replay 检查 spec 与 publisher 均使用 `Number.isSafeInteger`；正常 `Date.now()` 时间戳仍可发布和解析。
