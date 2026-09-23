# ADR-0607：原版页书签切换可撤销化（PAGE_BOOKMARK companion）

- 状态：Accepted
- 日期：2026-09-23
- 阶段：Phase 640
- 证据：`docs/migration/evidence/original-page-bookmark-undoable-jadx-2026-09-23.md`
- 关联：ADR-0508（书签寄存器模型）、ADR-0602/0605（companion op 先例）

## 背景

原版 `ae2` variant 0 把书签切换编码为 `u5j.s` ModifyPage（掩码 6 → 仅
字段 3 oz9 寄存器），经 `x82.I(m1d, ops, dof, ...)` 应用；`dof`/`cof`
是显式撤销策略标记（`cof.toString() == "NotUndoable"`），`ae2`/`zd2`
全部页操作传 `dof`——书签切换在原版可撤销。

Harmony 侧 `toggleCurrentPageBookmark` 只调用
`persistOriginalPageBookmark` 落 ModifyPage op，不推
`UndoableAction`：撤销栈对书签变化无感知，属真实行为缺口。

## 备选方案

1. **复用 UPDATE_PAGE / PageSettingsAction**：不可行。
   `PageStructureOpCodec.samePageSettings` 刻意不含 `bookmarked`
   （ADR-0508：书签是 oz9 LWW 寄存器，不是 nz9 结构属性）；
   `PersistentHistory.changedPages` 同样排除。书签唯一变更在结构编码下
   无差异，`classifyPageStructureMutation` 判为 no-op——无法编码。
   修改 `samePageSettings` 纳入 `bookmarked` 会把书签变更混进
   `UPDATE_PAGE` 结构载荷并污染 Rotate 等既有路径的相等性语义。
2. **独立 companion op（采用）**：与 `DUPLICATE_PAGE`/
   `DELETE_PAGE_COMPENSATION` 同一模式——同步 op（ORIGINAL_MODIFY_PAGE）
   照旧落 journal 供 outbound，另写一条仅服务本地历史的
   `PAGE_BOOKMARK` companion 携带 before/after 寄存器值。
3. **无 companion、仅内存动作**：重启即丢，违背既有持久历史契约
   （UndoRedoManager 恢复依赖 operation_log 内 PUSH 标记 op）。

## 决策

- `OpType.PAGE_BOOKMARK = 6`，codec `PageBookmarkOpCodec`（`NPBK`
  magic）：载荷 `fromRevision/toRevision/pageId/bookmarkedBefore/
  bookmarkedAfter`，校验版本单步、寄存器必须翻转、拒绝尾随字节。
- `PageRepository.setPageBookmarked` 增加可选 `HistoryMetadata`：
  - 原版页：`persistOriginalPageBookmark` 落 ModifyPage（reducer 内
    `advanceStructureRevision`），随后校验版本 +1 并追加 companion；
  - legacy 页：直写 `page_info.bookmarked`，以
    `appendStructureMutation` 同款守卫自增 `structure_revision` 后追加
    companion；
  - 寄存器已是目标值 / 版本未前进 → fail-closed 回滚。
- `UndoableActionType.PAGE_BOOKMARK = 26`，`PageBookmarkAction` 携带
  `bookmarkedBefore/After`；撤销按 before、重做按 after 重放
  `setPageBookmarked`（UNDO/REDO effect 的 companion 记录真实迁移），
  `validatePageActionState` 要求页唯一且当前寄存器等于预期源值。
- `PersistentHistory` 物化 `PAGE_BOOKMARK` companion 为
  `PageBookmarkAction`（重启恢复）。
- `NoteCanvasView.isPageAction` 收录该类型，走既有异步页历史通道。

## 边界与差异

- 撤销/重做**不改动页选中**——原版无可考的选择迁移语义，且页书签图标
  渲染自 `pages[]` 物化态，无需选择联动。
- 原版支持多页书签批量切换；Harmony 编辑器当前仅单页操作（多选页管理
  为已登记独立差异项）。companion 载荷为单页记录，将来若引入多选，
  每页一条 ModifyPage + 一条 companion（或扩为复合载荷）即可扩展。
- legacy（非原版对齐）笔记的书签切换同样可撤销：companion 与原版
  页路径同型，版本自增改由仓储守卫完成。

## 验证

- Replay `d04-original-page-bookmark-undo.mjs`：44 断言（ae2/u5j.s/
  dof-cof 证据钉 + codec/仓储/物化/UI 锚点）。
- `d02-original-page-bookmark-parity.mjs`：50 断言，签名钉更新后仍绿。
- 全量 Desktop Replay 525/525；`note@ohosTest` 与 `note@default`
  clean assembleHap 均 BUILD SUCCESSFUL。
