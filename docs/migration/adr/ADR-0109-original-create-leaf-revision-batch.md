# ADR-0109: 原版 Paste 叶实体 CREATE 共享页面 revision batch

## 背景

原版 `lg2.g()` 把递归收集的叶实体交给 `u5j.c()` 复制，并由实际产生的 `CREATE_GROUP`
恢复 Group 根选择。因此完整 Group Paste 必须先产生全部叶 CREATE，再 bottom-up 产生 Group，且作为
一个用户操作提交。Harmony 现有 `CREATE_BLOCK`/`INSERT_TEXT` 已可共享 `OriginalPageMutationBatch`，
但 `CREATE_INK` 与 `CREATE_SHAPE` 每应用一条就立即递增页面 revision，无法组成单 revision 的复合事务。

## 决策

- `OriginalCreateInkOperationApplier` 增加 typed-payload batch 入口。可见 Ink 快照仍写计划时的
  `target.revision + 1`，只向共享 batch 登记 `recordInk()`；没有 batch 时维持原来的立即 revision
  更新及搜索失效行为。
- `OriginalShapeGroupOperationApplier` 增加只接受 type 18 CREATE_SHAPE 的 batch 入口。可见 Shape
  快照同样写 `target.revision + 1`，登记 `recordBlock(target, false)`，仅独立调用才自行 flush。
- CREATE_BLOCK、INSERT_TEXT、CREATE_INK、CREATE_SHAPE 可在后续同一数据库事务中共享一个 batch；
  batch 对同一页面合并 Ink/Text 标志，并在最终 `flush()` 以旧 revision 为 CAS 条件只递增一次。
- tombstone 命中的隐藏 CREATE 不改变活动/归档页面快照，因此不登记页面 revision；这与既有 reducer
  语义保持一致。
- 本阶段只提供 reducer 原语，不把循环调用独立 writer 冒充原子 Group Paste。复合事务、NCP1 history
  companion 和最终 Group 图仍由下一阶段一次性提交。

## 后果

后续 `StrokePersistence` 可以在一个 transaction 内应用多种叶 CREATE，而所有同页快照拥有相同的
新 revision，页面行也只前进一次。共享 batch 若观察到页面目标或旧 revision 不一致会拒绝，flush
CAS 失败会使外层事务整体 rollback，避免产生部分 Paste 或多次 revision。
