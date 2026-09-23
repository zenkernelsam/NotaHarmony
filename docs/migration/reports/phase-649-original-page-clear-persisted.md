# Phase 649 — 页面清空的持久层落地（非当前页 / 批量 Clear）

日期：2026-09-23 · 依据 ADR-0616 · 接续 Phase 647/648 登记的 fail-closed 项

## 目标

关闭 ADR-0614/0615 登记的 Clear 限制：原版 `fd2` case1 → `de2.n`
→ `ae2` variant 1 按页键作用于任意页，Harmony 此前只有画布
`clearPageSignal` 管线（绑定当前页）。

## 原版证据

- `de2.n(list)`：空集 fail-closed + MODEL 日志；非空经
  `xj2.A(..., new ae2(this, list, null, 1), 3)` 批应用。
- `ae2` case1：逐页收集 `x09.j.m(pageKey).keySet()`（页内全部
  元素键）→ `u5j.l(x09, ids, null, 14)` DELETE_ENTITIES op →
  `x82.I` 记帐通道（`dof` = undoable，Phase 640 已证）。
- `n9j` tc2 default(case6)：`de2.n(au1.T1(f))` 对整个选中集
  下发，执行后保持选择态。

## 实现

### `StrokePersistence.clearOriginalPageContent`

- `editorPersistenceMutex` 内事务：`readEligibleOriginalInkPage`
  门禁 → `loadCurrentSnapshot` 全量活动元素（空页返回 `null`）→
  `createPageMutation(rev, rev+1, current, [])`（断言分类为
  DELETE_ELEMENTS）→ `OriginalDeleteEntitiesOperationApplier`
  可见性删除页内全部元素与成员全集被覆盖的组 →
  `rebuildPageSearchState` 重建空页快照/搜索态 →
  companion `OpType.DELETE_ELEMENTS` op（`encodePageMutationOp`
  + `history` actionId）。
- 事务内校验：revision 恰进一位、物化后页为空；任一不满足
  整体回滚。

### `NotePage.clearPageAt`

- 当前页 → `clearPageSignal++`（画布选择→删除→撤销一体管线
  不变）；
- 非当前页 → `flushCurrentPage` → `preparePageAction` 取
  HistoryMetadata → 持久层清空 → `pushPageAction`
  （`PERSISTED_PAGE_MUTATIONS`：撤销经画布导航到该页 + 回放
  mutation 还原）；`pushPageAction → notifyUndoRedo →
  pageContentVersion++` 联动 `thumbRevision` 刷新缩略图。

### UI 解锁

- cell 菜单 Clear 移除 `if (this.selected)` 门控（任意页可用）；
- 选择工具条 Clear 对任意非空选中集启用，
  `dispatchPageSelectionAction('clear')` 逐页 `clearPageAt`，
  保持选择态（tc2 case6 不退出）。

## 差异登记（ADR-0616）

- 批量 Clear 逐页记帐（每页一条撤销动作），原版 ae2 单批——
  与 ADR-0615 批量历史合并同一登记项。
- 组删除仅覆盖"成员全集在本页"的组；跨页残留组保留。

## 验证

- 专项 Replay `d05-original-page-clear-persisted.mjs`：19/19。
- `d05-original-page-context-menu.mjs` 20/20、
  `d05-original-page-multiselect.mjs` 31/31（fail-closed 断言
  已更新为新语义）。
- 全量 Desktop Replay：534 项全绿。
- `note@default` / `note@ohosTest` 双 HAP 构建 0 错误。
- 未启动模拟器/真机/Hypium。
