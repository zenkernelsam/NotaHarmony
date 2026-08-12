# ADR-0130：笔记移入文件夹与目标校验同事务

日期：2026-08-12

## 决策

`moveNoteToFolder` 纳入 `FolderRepositoryImpl.writeMutex`，并在同一 relationalStore 事务中检查目标文件夹、更新 `note_meta.folder_id` 和提交。目标不存在、笔记不存在或提交失败都回滚。

## 原版对齐

原版库页把笔记归属和文件夹状态作为同一库状态链更新；Harmony 侧不能在检查后释放写入边界，否则并发删除/移动会产生悬空归属或误报成功。
