# ADR-0146: 备份恢复全对象校验门

## 决策

云恢复在调用任何 `NoteImporter.importFromData` 前，必须确认 `failedNoteIds` 为空且 `verified.length` 等于 manifest 条目数。否则终止整个批次，本地恢复数为零。

## 原因

manifest 表示一个完整备份批次。部分对象缺失或 hash 不匹配时继续导入其他对象，会把原子集合静默拆开，用户无法区分完整快照与残缺恢复。

## 验收

静态 replay 检查校验门位于导入循环之前。多笔记数据库写入阶段的事务性另行闭环。
