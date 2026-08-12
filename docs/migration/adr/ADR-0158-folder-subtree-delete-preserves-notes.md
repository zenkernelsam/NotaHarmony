# ADR-0158: 删除文件夹子树时保留笔记

## 决策

删除文件夹前，在同一数据库事务中遍历目标文件夹的完整子树，把每个子文件夹下的笔记 `folder_id` 设为 NULL，再删除目标文件夹。数据库对 `folder.parent_id` 的级联删除因此不会删除笔记。

## 原因

当前 schema 使用 `ON DELETE CASCADE` 删除子文件夹。旧实现只迁移目标文件夹直属笔记，父文件夹带子文件夹时会让后代笔记随文件夹级联丢失。文件夹删除不应成为笔记删除操作。

## 验收

静态 replay 检查删除方法先查询完整 folder 集合、对 `isFolderInSubtree` 命中的每个 folder 更新 note_meta，再执行 folder delete，且全部操作位于同一事务。
