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
- 第一种已接入的载荷为 `PAGE_SNAPSHOT`。它包含 pageId、revision 及按 z-order 排列的 elementId/kind/payload，使用有版本
  magic 的长度前缀二进制 codec，可独立解码和拒绝截断、尾随或超预算数据。
- 页面快照替换、revision 增长、搜索索引更新和日志 append 必须在同一 SQLite 事务内完成。任一步失败全部回滚。
- opId 暂定为 note 范围内确定性的 `page-snapshot:{pageId}:{revision}`，避免重试生成第二个身份。它不是原版
  `timestamp/siteId` 组合，不用于声称同步等价。
- 写入前逐项比较 elementId、kind、顺序和 payload 字节。完全相同的页面不增加 revision，不重写索引，也不追加恢复点。

## 后果

`OpStore` 现在有真实实现，且正式页面保存会产生可回放的追加记录，因此旧 D-19 的“接口零实现”缺口可以关闭。日志与当前快照
原子一致，可作为后续崩溃恢复、压缩和细粒度操作迁移的基础。

这不关闭 D-02，也不等价于原版 ClientOp。后续仍需实现：元素/页面细粒度 op serializer、editor site 与单调 opId、操作回放、
跨会话 Undo/Redo、checkpoint/compaction、损坏日志恢复、导入映射，以及同步上传和聚合元数据。完成这些之前，产品只能把
`PAGE_SNAPSHOT` 称为本地恢复点，不能声称具有原版协作或增量同步语义。
