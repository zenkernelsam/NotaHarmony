# ADR-0111: 原版 Group Paste 复合 type-25 Undo/Redo

## 背景

Group Paste 的叶实体和所有 nested/top Groups 必须共同可见或共同隐藏。分别执行普通元素 Undo 和
Group Undo 会产生中间状态，也不能代表原版 `DELETE_ENTITIES` type 25 的向量语义。Phase 133 已把
CREATE 与 NCP1 PUSH 放入一个事务，但专用 history action 尚无执行路径。

## 决策

- `applyOriginalClipboardPasteHistory()` 解码并深拷 NCP1，用标准 `replayPageMutation()` 验证当前整页
  source order/payload 并推导目标整页；不能把 `beforeElements/afterElements` 误当整页，它们只包含
  受影响实体。
- 一次 Undo/Redo 收集 NCP1 的全部新叶 identity 和全部 Group identity，编码成一条 type-25：Undo
  全部进入 delete vector，Redo 全部进入 undelete vector。既有 reducer 对受影响页面去重，因此页面
  revision 只增长一次，并在最后统一刷新 Group layering。
- Group Stored CREATE payload、当前 active/inactive 状态、目标页面字节/层序、目标 Group 状态和
  `revision + 1` 全部通过后，才写同一 NCP1 的 UNDO/REDO history companion 并提交。
- `NoteCanvasView` 为专用 action 增加非 coalesced handler。UI 先用同一 page replay 和 Group 状态做
  快速拒绝，数据库事务成功后才移动 Undo/Redo 栈、安装元素与 Group 状态。
- Paste preflight 新增 `leaves + groups <= MAX_ORIGINAL_DELETE_ENTITY_COUNT`，保证任何允许提交的 Paste
  都可由一条 type-25 撤销，不产生“可粘贴但不可撤销”的状态。

## 后果

重启恢复的专用 action 和未来运行时新 Paste 使用相同 NCP1 operation，均可执行原子 Undo/Redo。
下一阶段只需让 `StrokeClipboard` 保存源 Group 图并在事务成功后把返回的 companion action 推入内存
history；数据层和 handler 不再需要兼容快照回退。
