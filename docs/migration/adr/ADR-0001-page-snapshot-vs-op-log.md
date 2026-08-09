# ADR-0001：页面元素快照与原版 Op Log 分离

- 状态：Accepted（过渡架构）
- 日期：2026-08-09
- 关联：M2-D-05

## 背景

NotaHarmony 曾把每页当前全部元素存进 `client_op`：保存时先删除该页全部行，再重新写入；`op_type`
恒为 INSERT，`op_id` 实际是 element id，`client_time` 实际承担图层顺序。这不是操作日志。

Notability 1.0.3 的 `ClientOp` 有不同且明确的语义：

- `e47.java:336-339`：列为 `noteId, op, uploadImmediately, hasTitle, title, opId, clientTime`，
  主键为 `(noteId,opId)`；`op` 是二进制操作载荷。
- `wp1.java:534`：DAO 逐条执行 `INSERT INTO ClientOp ... VALUES (...)`。
- `iq1.java:17-19`：按 `(noteId,opId)` 删除或更新单条操作。
- `ft0.java:37,252`：按 opId 的时间部分、clientTime 和 title op 聚合，并按载荷长度分片读取。

因此，继续把 Harmony 的全量当前状态称为 ClientOp，会让接口、表结构和同步/Undo 能力产生错误承诺。

## 决策

当前可运行存储正式命名为 `page_element_snapshot`，字段明确为：

```text
(note_id, page_id, element_id, kind, payload, revision, element_order)
```

- 每次提交原子替换单页快照。
- `revision` 是持久化的页面快照版本；`element_order` 是稳定图层顺序。
- `kind` 区分 stroke/text，payload 仍是当前 JSON 适配格式。
- 会话 Undo 继续由 `UndoRedoManager` 管理，不宣称跨会话 Undo。
- `OpStore` 保持独立接口，不允许以 snapshot 表提供伪实现。

数据库 v7 将旧 `client_op` 内容无损迁入 snapshot；旧载荷无法仅靠 SQL 安全解析 kind，迁移行暂记 kind=0，
读取仍以 payload 内的判别字段为准。页面首次重新保存后会写成明确的 stroke=1/text=2。

## 后果

这项决策修复命名和行为不一致，但不等于完成原版 op-log。同步、增量回放和跨会话 Undo 仍未实现。

恢复完整原版模型前必须另立 ADR，并至少完成：真实 OpSerializer、单调 opId/siteId、append-only DAO、
页面/元素 op 组合与回放、Undo/Redo op、压缩/快照边界、损坏恢复、导入映射以及同步元数据。完成这些条件前，
不得把 `page_element_snapshot` 改名回 `ClientOp`，也不得声称已具备原版同步语义。
