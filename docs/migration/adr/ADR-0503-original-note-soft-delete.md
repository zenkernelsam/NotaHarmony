# ADR-0503：笔记软删（Recently Deleted）采用本地等价模型而非完整 ClientNoteUpdate 队列

- 状态：已接受（2026-09-22，Phase 531）
- 背景：Phase 530（ADR-0502）逐表比对确认原版 SCHEMA-D1——原版笔记删除为
  `ClientNoteUpdate` 四类更新（EDIT/DELETE/UNDELETE/PERMANENTLY_DELETE）+
  `PermanentlyDeletedNote` 墓碑 + `ClientPivot` 合并查询 + "Recently Deleted"
  30 天自动清除；Harmony 此前为直接硬删。

## 决策

不复刻 `ClientNoteUpdate` 队列表，改用本地等价模型：

1. `note_meta.deleted_at INTEGER`（NULL=活跃，非空=移入回收站时间戳）承担
   DELETE 行角色；`permanently_deleted_note(note_id)` 承担墓碑表角色。
2. `trashNote`/`restoreNote` 为单 UPDATE；`deleteNote` 为墓碑 + 级联硬删；
   `purgeExpiredTrash` 在资料库/回收站页加载时结算 30 天过期。
3. 墓碑使被永久删除的 id 永久占用：`NoteImporter.noteIdExists` 覆盖墓碑表，
   重导入旧包时分配新 id，绝不复活。

## 理由

- 原版的队列与 pivot 存在的唯一理由是**多设备乐观同步**（EDIT 行把
  createdAt/favorite/lastOpened/folderId 合并为一条待上行的更新）。Harmony 无
  同步端点，复刻队列表只会产生永不消费的写放大与死代码。
- 全部用户可见语义——软删进回收站、恢复、永久删除不可复活、30 天自动清除、
  回收站列表与空态文案——在等价模型下逐条对齐，且有 Replay 可执行复放。
- 若未来接入同步，演化路径清晰：`deleted_at` + 墓碑即 DELETE/PERMANENTLY_DELETE
  的最小投影，可在其上生长队列表而不破坏现有语义。

## 后果

- `DB_VERSION` 66→67；`MIGRATIONS[67]` 为既有库补列与建表，`ddlList` 为新库幂等建表。
- `deleteNote` 顺带补上 `search_item` 清理（修复永久删除遗留索引孤儿）。
- 备份/导出/搜索自然排除回收站笔记。
- 代价：失去队列式更新历史（本地无消费者）；回收站为逐条操作而非原版的选择式批量操作（列为后续增强）。
