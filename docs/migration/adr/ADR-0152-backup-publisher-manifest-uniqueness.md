# ADR-0152: 备份发布前校验 manifest 唯一性

## 决策

`BackupBatchPublisher.publish()` 在任何远端写入前，拒绝重复 `noteId` 以及 `safeObjectId()` 归一化后重复的对象文件名。拒绝结果保持 `OBJECT_UPLOAD` 阶段，远端不产生该批次的对象或 manifest。

## 原因

`parseBackupBatch()` 已要求 noteId 和 fileName 唯一，但发布器此前在上传全部对象后才构造 manifest，没有执行同一约束。重复输入会留下已上传对象并发布一个恢复器无法接受的批次，破坏“失败批次不可见为成功”的边界。

## 验收

静态 replay 检查唯一性集合位于 `ensureBackupDir()` 之前，且重复输入在首次远端写入前返回失败。正常不同笔记仍生成稳定不冲突的对象名。
