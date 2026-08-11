# ADR-0107: 原版 Group 剪贴板复合 Paste 协议

## 背景

原版 `lg2.g()` 会递归展开选中 Group 的后代，再由 `u5j.c()` 复制实体并生成新操作。
`lg2.e()` 不从源选择猜测新 Group，而是从实际生成的 operations 中收集 `CREATE_GROUP`，
排除作为其他 Group 成员的 nested Group，最后用剩余顶层 Group 恢复 Paste 后选择。

现有 `OriginalGroupMutationOpCodec` 服务普通 Group/Ungroup：每次只允许一个 Group，并要求
变更前后页面成员完全相同。Paste 会同时新增页面实体与多个 Group，因此放宽该 codec 会削弱
普通 Group 操作的严格验证，也不能表达 Paste 的原子图。

## 决策

新增独立的 `NCP1` (`OriginalClipboardPasteMutation`) history companion：

- `pageMutation` 必须由生产 `PageMutationOpCodec` 验证为纯 `INSERT_ELEMENTS`；
- `groups` 按 nested 到 parent 的顺序保存，与原版 CREATE_GROUP 生成顺序一致；
- `topGroupIds` 必须恰好等于无父 Group 的根集合，用于成功提交后的选择恢复；
- 新增叶实体和 Group ID 必须是 canonical operation identity，Group ID 不得与页面实体冲突；
- Group 成员只能引用本次新增叶实体或列表中更早的 Group；每个成员最多属于一个父 Group，
  因而循环、前向引用和多父图均在编码前被拒绝；
- 允许一次 Paste 同时包含顶层 Group 与独立未分组叶实体；
- 复合结构整体受 `MAX_OPERATION_ELEMENTS` 与 `MAX_OPERATION_BYTES` 约束。

现有 `NGM1` 单 Group codec 保持不变。

## 后果

本协议为后续一个数据库事务内写入叶 CREATE、bottom-up CREATE_GROUP、单 revision 和一个
history companion 提供确定边界。Phase 130 不把 codec 存在冒充为 UI 已可用；生产事务、
持久历史物化、复合 type-25 Undo/Redo 和剪贴板 Group 图接线继续在后续阶段完成。
