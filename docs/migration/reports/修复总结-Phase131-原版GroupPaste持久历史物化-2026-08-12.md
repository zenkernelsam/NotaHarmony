# Phase 131 修复总结：原版 Group Paste 持久历史物化

## 问题

`NCP1` 不能物化为普通页面 mutation，因为那会丢失 nested/top Group；也不能伪装为现有
`GROUP_ELEMENTS`，因为后者只表达单 Group 且禁止页面成员变化。若没有专用 action，应用重启后
无法可靠恢复复合 Paste 的一个用户级 Undo/Redo 单元。

## 已完成修复

- 新增本地 `OpType.ORIGINAL_CLIPBOARD_PASTE` history companion 分类和
  `UndoableActionType.ORIGINAL_CLIPBOARD_PASTE`。
- 新增专用 `OriginalClipboardPasteAction`，保存经过验证的 NCP1 operation，并按真实 payload
  计入 history 内存预算。
- `PersistentHistory` 只接受恰好一条 NCP1 companion；解码成功后从内部 page mutation 恢复
  pageId。混入多条 operation 或 payload 截断/损坏会严格拒绝。
- ArkTS fixture 覆盖 PUSH 后 UNDO 的 redo 栈物化、专用 action 类型、页面归属、多 operation
  混装和损坏字节。
- 新增 ADR-0108 与 `d02-original-group-paste-history.mjs`。

## 验证与后续

- 专项输出为
  `originalGroupPasteHistory=dedicated-ncp1-single-companion-push-undo-redo-strict-materialization`；
  全量桌面 replay 为 `TOTAL=117 FAILED=0`，`git diff --check` 通过。
- 执行 `hvigorw clean` 后严格串行构建 `note@ohosTest` 与 `note@default`，两套 HAP 均为
  `BUILD SUCCESSFUL`，只有项目既有 deprecated/exception-handling warning。
- 未启动模拟器、虚拟机、真机或 Hypium。
- 下一阶段实现 `StrokePersistence` 的一次事务：叶 CREATE、bottom-up CREATE_GROUP、单 revision、
  NCP1 companion 与失败整体 rollback；随后再接复合 type-25 Undo/Redo 和 UI。
