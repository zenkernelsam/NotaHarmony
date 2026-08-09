# ADR-0003：追加式页面恢复日志作为原版 Op Log 的过渡基础

- 状态：Accepted（过渡架构）
- 日期：2026-08-09
- 关联：D-19、D-02、ADR-0001

## 背景

ADR-0001 已把正式页面状态命名为 `page_element_snapshot`，并禁止继续把“删除整页再重写”的快照表冒充原版
ClientOp。该决定修正了存储语义，但 `OpStore` 仍只有接口，正式编辑路径没有产生任何可追加、可排序、可回放的操作记录。

Notability 1.0.3 的证据表明 ClientOp 是独立的追加存储：

- `e47.java:336-338` 创建 `ClientOp(noteId, op, ..., opId, clientTime)`，主键为 `(noteId, opId)`；
- `wp1.java:534` 使用普通 `INSERT INTO ClientOp`，重复身份不会被 replace 掩盖；
- `iq1.java:17-19` 只按 `(noteId, opId)` 删除或更新单条 op；
- `q0.java:437` 按 noteId 删除该笔记的全部 ClientOp。

原版 `op` 是二进制细粒度操作载荷，并带同步、聚合和 editor site 身份。Harmony 当前尚未完成这些语义，不能根据未知字段
猜测 FlatBuffer 映射，也不能把现有 JSON 元素快照改名为原版 op。

## 决策

新增与当前状态表完全分离的 `operation_log`：

```text
(sequence, note_id, op_id, op_type, payload, client_time)
```

- `sequence` 是本地单调自增顺序；`(note_id, op_id)` 唯一，append 使用普通 INSERT。
- 查询按 `(client_time, sequence)` 排序，解决同毫秒写入顺序不确定。
- v13 第一阶段曾接入 `PAGE_SNAPSHOT/NPS1`，它包含 pageId、revision 及完整有序元素。该 codec 保持可读，用于兼容已生成的
  本地恢复点，但不再作为每次保存的默认载荷。
- 第二阶段正式保存改写 `NPM1` 页面 mutation：记录 from/to revision、受影响元素的 before/after payload，以及页面完整
  before/after 身份层序。新增、删除、替换和纯重排分别使用明确 opType，不再为未变化元素重复保存 payload。
- mutation replay 必须同时匹配源 revision、完整源层序以及所有受影响源元素字节；任何不匹配、重复身份、矛盾层序、截断、
  尾随、非法 UTF-8 或超预算载荷均拒绝。相同 mutation 可严格正向或反向回放。
- 页面快照替换、revision 增长、搜索索引更新和日志 append 必须在同一 SQLite 事务内完成。任一步失败全部回滚。
- 新 opId 为 note 范围内确定性的 `page-mutation:{pageId}:{fromRevision}:{toRevision}`，避免重试生成第二个身份。它不是原版
  `timestamp/siteId` 组合，不用于声称同步等价。
- 因当前增量接口只有 `sinceTime`，正式保存会在事务内分配 `max(wallClock,lastClientTime+1)`，确保严格 `>` 游标不会因同毫秒
  或系统时钟回拨漏 op。`sequence` 仍提供数据库内稳定次序。
- 写入前逐项比较 elementId、kind、顺序和 payload 字节。完全相同的页面不增加 revision，不重写索引，也不追加恢复点。
- 第三阶段新增 `NPG1` 页面结构 mutation。它保存 note 范围的 from/to `structure_revision` 和完整 before/after
  `PageInfo` 有序集合，分别映射 `CREATE_PAGE`、`DELETE_PAGE`、`UPDATE_PAGE`、`REORDER_PAGES`。replay 必须逐字段匹配
  当前页面集合和 revision，支持严格正向与反向恢复；重复页面、非连续 pageIndex、复合设置加重排、非规范数值、截断或尾随载荷
  均拒绝。
- v14 在 `note_meta` 增加 `structure_revision`。opId 确定生成为
  `page-structure:{fromRevision}:{toRevision}`；页面写入、revision 条件推进和日志 append 同事务，失败整体回滚。普通新建笔记的
  默认首页也在笔记创建事务内产生 `0→1` 的 `CREATE_PAGE`，导入专用空笔记则由逐页导入依次产生页面 op。
- `PageRepository` 的设置写入不再修改 `page_index`；排序必须经过完整成员集合校验。删除不存在页或最后一页、更新不存在页、
  重排中的重复/缺失/外来 ID、以及任何影响行数异常都会在提交前失败。无变化设置和无变化排序不推进 revision、不追加日志。

## 后果

`OpStore` 现在有真实实现，且正式页面保存会产生可回放的追加记录，因此旧 D-19 的“接口零实现”缺口可以关闭。日志与当前快照
原子一致，可作为后续崩溃恢复、压缩和细粒度操作迁移的基础。

这不关闭 D-02，也不等价于原版 ClientOp。元素与页面结构 mutation serializer、双向 replay 和原子追加已经建立，但元素保存队列
仍可能把连续 UI 动作合为一次数据库 mutation，UndoRedoManager 也未从持久化 mutation 恢复。后续仍需实现：逐动作边界、
跨会话 Undo/Redo、editor site/原版式单调 opId、checkpoint/compaction、损坏日志恢复、同步导入映射，以及
同步上传和聚合元数据。完成这些之前，不得声称具有原版协作或完整增量同步语义。
