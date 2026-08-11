# ADR-0110: 原版 Group Paste 单事务生产路径

## 背景

原版 `lg2.g()` 递归收集 Group 后代并把叶实体交给 `u5j.c()` 的模型复制路径，`lg2.e()` 再从实际
生成的 CREATE_GROUP operations 排除 nested Groups、恢复顶层选择。Phase 130～132 已分别提供 NCP1
协议、专用持久历史和共享页面 revision batch，但尚没有把它们组合成一次原子生产提交。

## 决策

- `StrokePersistence.commitOriginalClipboardPaste()` 接受叶实体顺序、bottom-up 源 Group 图、精确根
  集合和非合并 PUSH history；在任何异步等待前深拷贝并二次验证 plan/history，避免调用方修改造成
  预检与提交不一致。
- 所有新 identity 只在同一个数据库 transaction 内分配。Ink、Shape、Text Block 与 Text 初始
  INSERT_STRING 共用一个 `OriginalPageMutationBatch`，同页所有快照写同一个 `old + 1` revision，
  页面行只 CAS 前进一次。
- 叶 CREATE 全部成功后，按源图顺序 bottom-up 分配并应用 CREATE_GROUP。每条原版 CREATE operation
  都写 upload-immediate operation journal；最后只写一条带用户 history 的 NCP1 companion。
- 提交前重新读取实际 Group-layered 页面顺序，验证旧元素字节未变、所有新元素恰好出现一次、所有新
  Group 精确物化，再据此生成纯 INSERT 的 NCP1 page mutation。任一 reducer deferred、CAS 冲突、
  快照/Group 偏差或 history 写入失败均 rollback identity 时钟、页面、状态表与 journal。
- 第一版严格支持 canonical Ink、Shape、非空无样式 Text。Image/Math、Styled Text 与 Shape RichText
  在零写入 preflight 明确拒绝，不降级成 Harmony snapshot。

## 后果

数据层现在具备忠实 Group Paste 的原子生产能力，并返回新叶实体、完整页面层序、新 Groups、顶层
Group IDs 和 NCP1 mutation。编辑器仍未调用该入口；下一阶段需实现复合 type-25 Undo/Redo，之后才
让 `StrokeClipboard` 保存源 Group 图并把 UI 切换到此事务。
