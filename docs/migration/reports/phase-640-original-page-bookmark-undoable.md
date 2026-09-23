# Phase 640 — 原版页书签切换可撤销化（PAGE_BOOKMARK companion）

- 日期：2026-09-23
- 证据：`docs/migration/evidence/original-page-bookmark-undoable-jadx-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0607-original-page-bookmark-undoable.md`
- Replay：`docs/migration/replays/d04-original-page-bookmark-undo.mjs`（44 断言）

## 原版行为

`ae2` variant 0（书签协程）对选中页逐页判定：任一选中页未书签 →
`oz9.BOOKMARKED`，全部已书签 → `oz9.UNBOOKMARKED`；随后
`m18.l0(u5j.s(x09, list3, null, null, oz9Var, 6))` 生成仅写字段 3
（oz9 书签寄存器）的 ModifyPage，经 `x82.I(m1d, ops, dof, iw3, this)`
日志通道应用。

`eof` 是撤销策略类型：`dof implements eof`（空标记 = 可撤销），
`cof implements eof` 且 `toString() == "NotUndoable"`。ae2/zd2 全部
页操作传 `de2Var.O`（dof）——**书签切换在原版可撤销**，与旋转页
（Phase 634）同通道同策略。

单页语义等价于 `next = !current.bookmarked`。

## Harmony 缺口（修复前）

`NotePage.toggleCurrentPageBookmark` → `setPageBookmarked` →
`persistOriginalPageBookmark`：落 ModifyPage op 并物化
`page_info.bookmarked`，但不推 `UndoableAction`——撤销栈无记录。

既有 `UPDATE_PAGE`/`PAGE_SETTINGS` 通道结构性不可承载：
`PageStructureOpCodec.samePageSettings` 刻意不含 `bookmarked`
（ADR-0508 寄存器/结构分离决策），书签唯一变更会被
`classifyPageStructureMutation` 判为 no-op。

## Harmony 对齐（本 Phase）

- `OpType.PAGE_BOOKMARK = 6` + `PageBookmarkOpCodec`（`NPBK` magic）：
  载荷 `fromRevision/toRevision/pageId/bookmarkedBefore/After`，
  校验版本单步 + 寄存器翻转 + 无尾随字节。
- `PageRepository.setPageBookmarked` 增可选 `HistoryMetadata`：
  - 原版页：ModifyPage reducer 内 `advanceStructureRevision`，随后校验
    版本 +1 并追加 `PAGE_BOOKMARK` companion；
  - legacy 页：直写 `page_info` 后同款守卫自增版本再落 companion；
  - 寄存器已是目标值 → fail-closed。
- `UndoableActionType.PAGE_BOOKMARK = 26` + `PageBookmarkAction`；
  `toggleCurrentPageBookmark` 构造动作 → `preparePageAction` →
  带 history 写仓储 → `pushPageAction`。
- `applyPageHistory` 撤销按 before、重做按 after 重放
  `setPageBookmarked`（UNDO/REDO effect companion 记录真实迁移）；
  `validatePageActionState` 要求页唯一且当前寄存器等于预期源值。
- `NoteCanvasView.isPageAction` 收录；`PersistentHistory` 物化
  companion 为 `PageBookmarkAction`（重启恢复撤销栈）。

## 与原版差异

- 原版 `u5j.s` op 流本身即历史单元；Harmony 分行同步 op
  （ORIGINAL_MODIFY_PAGE，无 history 标记）+ 本地 companion——与
  DUPLICATE_PAGE / DELETE_PAGE_COMPENSATION 既有 companion 架构一致。
- 撤销/重做不迁移页选中（原版无可考选择语义；书签图标渲染自物化态）。
- 多页批量书签为已登记独立差异项（编辑器当前单页操作）。

## 验证

- `d04-original-page-bookmark-undo.mjs`：**44/44**。
- `d02-original-page-bookmark-parity.mjs`：**50/50**（签名钉更新）。
- 全量 Desktop Replay：**525/525 PASS**。
- `note@ohosTest` / `note@default` HAP：clean 静态构建成功
  （无新增 ArkTS 错误）。
- 未启动模拟器、虚拟机、真机或 Hypium；T-042 保持 Goal 最后任务。
