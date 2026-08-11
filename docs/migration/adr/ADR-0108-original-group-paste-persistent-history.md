# ADR-0108: 原版 Group Paste 的专用持久历史动作

## 背景

Phase 130 的 `NCP1` 同时描述页面 INSERT、多个 Group 和顶层选择根。把它恢复成普通
`PERSISTED_PAGE_MUTATIONS` 会丢失 Group/选择语义；恢复成 `GROUP_ELEMENTS` 又违反该动作只允许
单 Group 且页面 membership 不变的契约。

## 决策

- 新增本地 history companion `OpType.ORIGINAL_CLIPBOARD_PASTE = 32`；它不是原版私有同步 payload，
  只用于 Harmony 重启后恢复用户级历史。
- 新增 `UndoableActionType.ORIGINAL_CLIPBOARD_PASTE = 19` 和专用 action，保留已经过 NCP1 验证的
  companion operation。
- `PersistentHistory.materializeAction()` 要求一个 Group Paste action 恰好包含一条 companion，
  解码并完整验证 NCP1 后才从内部 page mutation 取得 pageId。
- 多条 operation 混装、截断/损坏 NCP1 或任何协议不变量失败都会使该历史恢复失败，不降级成
  普通元素动作，也不猜测 Group 状态。
- history budget 按实际 NCP1 payload 和 operation identity 计费。

## 后果

后续事务生产路径可以把全部原版 CREATE operations 与一条 NCP1 history companion 放在同一事务，
而 persistent history 只把 companion 物化为一个用户动作。Undo/Redo 的实际 type-25 可见性事务和
编辑器 handler 仍需随后接入；在生产 action 出现前，不暴露半完成的 UI 路径。
