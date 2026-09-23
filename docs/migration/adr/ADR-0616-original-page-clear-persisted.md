# ADR-0616 原版页面清空的持久层落地

- 状态：Accepted
- 日期：2026-09-23
- 关联 Phase：649
- 接续：ADR-0614（cell 菜单 Clear 仅当前页 fail-closed）、
  ADR-0615（批量 Clear 仅当前页 fail-closed）
- 证据：`docs/migration/evidence/original-page-clear-persisted-jadx-2026-09-23.md`

## 背景

原版 Clear Page（`fd2` case1 → `de2.n` → `ae2` variant 1）按页键
作用于**任意页**：收集页内全部元素键 → `u5j.l` 实体删除 op →
`x82.I` 记帐通道（可撤销）。Harmony Phase 647/648 的 Clear 只能
走画布 `clearPageSignal`（选择→删除→撤销一体管线），该管线绑定
当前已加载页，导致：

1. cell 菜单对非当前页的 Clear 被条件隐藏（fail-closed）；
2. 选择工具条 Clear 仅当选中集恰为当前页时可用。

## 决定

1. `StrokePersistence.clearOriginalPageContent(noteId, pageId,
   history)`：持久层页清空。
   - `readEligibleOriginalInkPage` 门禁（非原版对齐页拒绝）；
   - `loadCurrentSnapshot` 取全量活动元素；空页返回 `null`
     （对齐画布 clear 的空页 no-op，不产生历史动作）；
   - `createPageMutation(rev, rev+1, current, [])` 构造
     DELETE_ELEMENTS 页变更；
   - 页内全部元素 + 成员全集被覆盖的组经
     `ORIGINAL_DELETE_ENTITIES` 可见性删除（与部分擦除同一
     写通道 `OriginalDeleteEntitiesOperationApplier`）；
   - 事务内校验：revision 恰进一位、物化后页为空；
   - companion `OpType.DELETE_ELEMENTS` op 挂
     `history`（actionId）→ 重启物化为
     `PERSISTED_PAGE_MUTATIONS`。
2. `NotePage.clearPageAt(pageIndex)`：
   - 当前页 → `clearPageSignal++`（画布管线不变）；
   - 非当前页 → flush 当前页 → `preparePageAction` 取
     HistoryMetadata → 持久层清空 → `pushPageAction`
     （`PERSISTED_PAGE_MUTATIONS`）。撤销时画布先导航到该页
     再回放 mutation 还原全部元素（既有路径）。
3. UI 解锁：cell 菜单 Clear 不再限当前页；选择工具条 Clear
   对任意非空选中集可用（`dispatchPageSelectionAction` 的
   `clear` 分支逐页 `clearPageAt`，保持选择态——对齐
   tc2 case6 不调 `de2.u()` 的语义）。

## 与原版差异（fail-closed / 登记后续）

| 原版 | Harmony | 处置 |
|---|---|---|
| ae2 v1 一次 op 流应用整个选中集 → 一步撤销 | 逐页 `clearPageAt` → 每页一条 `PERSISTED_PAGE_MUTATIONS` | 登记：批量历史合并需多页复合 action（同 ADR-0615 表项） |
| 组随页内成员全集失效 | 仅删除成员全集被本页覆盖的组；跨页残留组保留 | 观测等价（原版组为页域模型） |
| 删除键空间 = `j.m(page).keySet()`（含不可见元素） | `loadCurrentSnapshot` 活动元素 + 可见性删除 | 已删除元素本已不可见，重复删除为 no-op |

## 验证

- 专项 Replay：`d05-original-page-clear-persisted.mjs` 19/19。
- 回归：`d05-original-page-context-menu.mjs` 20/20、
  `d05-original-page-multiselect.mjs` 31/31（更新两处
  fail-closed 断言）。
- 全量 Desktop Replay：534 项全绿。
- `note@default` 与 `note@ohosTest` 双 HAP 构建 0 错误。
