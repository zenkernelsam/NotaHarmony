# Phase 651：批操作一步撤销（PAGE_BATCH 跨页历史归并）

日期：2026-09-23
接续：Phase 648（多选批操作）、Phase 649（持久化清空）、Phase 650（锚定）
ADR：ADR-0618
证据：`docs/migration/evidence/original-page-batch-history-jadx-2026-09-23.md`
专项 Replay：`docs/migration/replays/d05-original-page-batch-history.mjs`（25 项）

## 原版行为（硬证据）

`ae2.invokeSuspend` 五个批变体均为同一模式：先把**全部**选中页的 op
汇总为一张表（`m18.l0(u5j.…)`），再对整表只调一次
`x82.I(m1d, list, dof, iw3, this)`。`x82.I` 把整表包成 `wq9` 项后以
单个 `pq1(12, list)` 交给 `m1d.v0` —— 一次应用 = **一步撤销**。

Harmony 此前逐页入栈（每页一条 `NONE` 轨历史），批操作需 N 次撤销；
`peekGroup` 的同页+时间窗归并天然拒绝跨页条目。

## Harmony 实现

1. `HistoryCoalesceTrack.PAGE_BATCH = 4`：显式批轨，非时间窗语义
   （`coalesceWindow` 恒 -1）。
2. `UndoRedoManager.beginPageBatch()/endPageBatch()` 批窗口（深度计数）：
   窗口内 `createHistoryMetadata` 盖写 `PAGE_BATCH` 轨 + 批次共享
   `actionTime`；`actionId` 仍逐条唯一（`restore()` 约束不变）。
   `actionTime` 兼作批次标识，强制单调递增；恢复出的批条目抬高
   批次时钟，重启后新批次标识永不与持久化批次碰撞。
3. `peekGroup` 新增批分支：锚为 PAGE_BATCH 时按
   `noteId + track + actionTime` 跨页归并相邻条目；非批锚维持
   原同页+时间窗规则，批条目不会被非批锚吸收。
4. 消费端 `performHistory`：批组跳过单页元素组守卫，落入既有单条
   派发链——每次只应用+提交栈顶一个子条目；`continuePageBatch`
   在每次提交后检查同批剩余并立即再入，跨页子条目经既有
   `pendingHistoryDirection`/`resumePendingHistory` 导航衔接，
   直到批耗尽。对用户 = 一次撤销/重做回滚整批。
5. 持久化通道：`PersistentHistoryMetadata` 与 `acceptPreparedHistory`
   上限扩到 PAGE_BATCH；`OpStoreImpl` 原样往返；`StrokePersistence`
   仅批可达的两个写者闸口放宽（`clearOriginalPageContent`、
   `commitOriginalDuplicatePageContent`），其余八个元素级写者保持
   `NONE` 严格闸口。
6. `dispatchPageSelectionAction` 整个 switch 包在
   `begin/end + try/finally` 内；单页 cell 菜单不包窗。

## 批内条目形态

- Add/Delete/Duplicate/Paste/Bookmark → 页操作条目（应用无需加载页）；
- 非当前页 Clear → `PERSISTED_PAGE_MUTATIONS`（应用前导航）；
- 当前页 Clear → 画布 `DELETE_ELEMENTS`（@Watch 同步派发在窗口内
  取批元数据）。

## 验证

- 专项 Replay：`D05_ORIGINAL_PAGE_BATCH_HISTORY_REPLAY_OK TOTAL=25`。
- `d02-original-history-coalesce-page-domain` 扩展批归并复算用例
  （跨页归并/批次标识边界/不吸收非批条目/跨 note 边界）：21/21。
- 全量 Desktop Replay：536 项全绿（`SUITE_TOTAL` 详见工作日志）。
- `note@ohosTest` / `note@default` clean 构建通过。

## 登记差异（见 ADR-0618）

- 含需加载页子条目的批撤销/重做后停在最后被导航页（原版无加载页
  概念）；纯结构批不导航，无此差异。
- 子操作中途抛错：已应用子集仍是一个合法批组，撤销可回滚
  （fail-closed）。
- 当前页 Clear 依赖 ArkUI @Watch 同步派发；真机若异步则该子条目
  脱离批组 —— 已记真机验收候选。
