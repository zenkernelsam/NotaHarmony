# ADR-0618 批操作一步撤销（PAGE_BATCH 跨页历史归并）

- 状态：Accepted
- 日期：2026-09-23
- 关联 Phase：651
- 接续：ADR-0615（批量操作）、ADR-0616（持久化清空）、ADR-0617（锚定）
- 证据：`docs/migration/evidence/original-page-batch-history-jadx-2026-09-23.md`

## 背景

原版 `ae2` 的每个批变体先把**全部**选中页的 op 汇总为一张表
（`m18.l0(u5j.…)`），再对整表只调一次 `x82.I` —— `x82.I` 把整表
包成 `wq9` 项后以单个 `pq1(12, list)` 交给 `m1d.v0` 应用。
即上游批操作 = 一次应用 = **一步撤销**。

Harmony Phase 648/649 的批操作逐页派发，每页各自入栈一条历史
（`coalesceTrack = NONE`），一次批删除需要 N 次撤销才能回滚。
`peekGroup` 的既有归并要求同 `pageId` + 时间窗，天然拒绝跨页归并。

## 决定

新增显式批轨 `HistoryCoalesceTrack.PAGE_BATCH = 4`，并引入批窗口：

1. **批窗口**：`UndoRedoManager.beginPageBatch()/endPageBatch()`
   （深度计数，防御嵌套）。窗口内 `createHistoryMetadata` 一律
   盖写 `coalesceTrack = PAGE_BATCH`、`actionTime = 批次共享值`；
   `actionId` 仍按条目唯一（`restore()` 拒绝重复 id 的约束不变）。
2. **批次标识**：`pageBatchActionTime = max(Date.now(),
   上一批次 + 1)` 单调递增；`acceptPreparedHistory` 遇到恢复的
   PAGE_BATCH 条目时抬高批次时钟。两次派发（含重启后）永不共享
   标识，杜绝错误归并。
3. **归并规则**：`peekGroup` 新增批分支——锚条目为 PAGE_BATCH 时，
   按 `noteId + track + actionTime 严格相等` 归并相邻条目，
   **不受 pageId 限制、不走时间窗**；非批锚条目维持原有
   同页+时间窗规则，PAGE_BATCH 的 `coalesceWindow` 恒为 -1，
   批条目永远不会被非批锚条目吸收。
4. **消费**：`performHistory` 对批组跳过单页元素组守卫，落入既有
   单条派发链——每次只应用+提交栈顶子条目；`commitHistory` 后
   `continuePageBatch` 检查剩余条目是否同属本批（同 actionTime），
   是则立即再入 `performHistory`。跨页子条目复用既有
   `pendingHistoryDirection → onRequestPage → resumePendingHistory`
   导航衔接，无需新机制。批组耗尽即停——对用户是一次撤销/重做。
5. **持久化**：`PersistentHistoryMetadata.validateHistoryMetadata`
   与 `acceptPreparedHistory` 上限扩到 PAGE_BATCH；`OpStoreImpl`
   原样往返 `coalesce_track`/`action_time`；`StrokePersistence`
   十个写者闸口中**仅**批可达的两个放宽
   （`clearOriginalPageContent` 与 `commitOriginalDuplicatePageContent`
   —— 批 Clear/Duplicate/Paste 的子操作携带批元数据），其余
   元素级写者保持 `NONE` 严格闸口（fail-closed）。
6. **派发点**：`dispatchPageSelectionAction` 的整个 switch 包在
   `begin/end` + `try/finally` 内；单页 cell 菜单
   （`dispatchPageContextAction`）不包窗，维持单条目语义。

## 批内条目形态

- 结构类子操作（Add/Delete/Duplicate/Paste/Bookmark）→ 页操作条目，
  应用时无需加载目标页；
- 非当前页 Clear → `PERSISTED_PAGE_MUTATIONS`（Phase 649 管线），
  应用前导航到该页；
- 当前页 Clear → 画布信号管线 `DELETE_ELEMENTS`（@Watch 同步派发，
  窗口内取批元数据），应用时导航回该页。

## 已知差异（fail-open 项，均登记）

- 撤销/重做批时，若批内含需要加载页的子条目，最终停在**最后一个
  被导航的页**而非批前查看页；原版无「加载页」概念，无从对齐。
  结构类纯批（delete/duplicate/paste/bookmark）不导航，无此差异。
- 批内某子操作抛错时 `finally` 收窗，已应用子条目仍构成一个合法
  批组——撤销回滚已应用子集（fail-closed，不产生半截批）。
- 当前页 Clear 经 @Watch 同步派发成立依赖 ArkUI prop 同步更新语义；
  若该假设在真机不成立，当前页 Clear 子条目会脱离批组成为独立
  撤销步 —— 记入真机验收清单候选项。

## 验证

- 专项 Replay `d05-original-page-batch-history.mjs`：25/25。
- 全量 Desktop Replay 536 项全绿。
- `note@ohosTest` / `note@default` clean 构建通过。
