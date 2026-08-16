# ADR-0239：原版 History Coalesce 的 Harmony Page Domain

## 状态

Accepted - Phase 261（2026-08-17）

## 背景

原版 1.0.3 `vnf.f()/g()` 会把相邻、同一 `pnf` track 且时间差不超过窗口的 UndoAndRedo 合并：文本插入/
删除为 2 秒，CREATE_INK 为 10ms。比较逐项更新 anchor，因此保持 pairwise adjacent 语义；原版对象没有
pageId，也没有显式页面边界检查。

Harmony 已采用全笔记、可持久恢复、动作携带 note/page identity 的历史栈。页面内容按 pageId 异步加载，而
`saveHistoryGroup()` 只能在一个页面的 SQLite transaction 中 durable replay。旧 manager 只按 track/time 形成
group；一旦 group 跨页，UI 的整组分支不接受它，却会继续落入单动作分支，造成一次 Undo 只移动顶部动作。

## 决策

- `peekGroup()` 保留原版 track、窗口、inclusive 边界和 pairwise anchor 更新。
- 在比较 track/time 前，要求 candidate 与当前 anchor 的 `noteId`、`pageId` 完全相同；任一 identity 改变即停止
  group。
- 该 identity 约束明确记录为 Harmony 异步页面加载和持久历史架构的安全适配，不宣称原版 `vnf/qnf` 有
  pageId 检查。
- `performHistory()` 对 `group.length > 1` 先强制验证同 note、同 page 且只含可由 page snapshot 重放的元素动作；
  不满足时记录错误并保持栈/文档不变，不允许静默只施加第一条。
- 同页 group 继续先在内存按 Undo/Redo 顺序施加，随后由 `saveHistoryGroup()` 单事务写完整 operation/revision，
  成功后才 `commitUndoGroup/commitRedoGroup`；失败恢复内存快照并保留原栈。
- 不新增 action-type/track 的一一映射限制。持久恢复会把原版文本 operation 物化成
  `PERSISTED_PAGE_MUTATIONS`，其 INSERT_TEXT/REMOVE_TEXT metadata 仍合法；特殊复合动作和页面动作由 UI
  domain guard fail closed。

## 后果

- 同页 10ms 连续 Ink 与 2 秒文本动作仍按原版一次 Undo/Redo 成组移动。
- 页面切换或异常混入另一 note 的恢复记录成为确定边界，旧页动作不会被当前页 group 吞入。
- 即使未来 metadata 损坏或新增 action 错配 track，多动作命令也不会退化成部分成功。
- 这是比原版更显式的 identity 不变量，但它服务于 Harmony 的异步单页 durable snapshot，避免跨架构照搬
  track/time 后产生原版没有的部分 Undo。

## 验证契约

- `UndoRedoManager.test.ets` 覆盖同页 pairwise 10ms、跨页截断、跨 note 截断、Undo/Redo group 顺序和 stale
  commit 原子拒绝。
- `d02-original-history-coalesce-page-domain.mjs` 固定原版 `vnf/qnf/pnf/tzc/fzc` 证据、Harmony identity
  边界、UI fail-closed 与单页事务。
- `d02-grouped-history.mjs` 继续验证完整 group 的 Undo/Redo 顺序、第二步注入失败 rollback 和 source mismatch。
- history recovery/checkpoint、page history、CREATE_INK、文本、剪贴板、Group、partial eraser 等相关 replay 与
  全量桌面 replay 必须通过。
- clean 后严格串行构建 `note@ohosTest` 与 `note@default`；不启动设备、模拟器、虚拟机、真机或 Hypium。

## 仍需设备验收

- 同页快速连续书写的一次 Undo/Redo 粒度和视觉反馈。
- 在历史顶部属于另一页时自动切页后完整施加，不闪回旧页内容。
- 重启恢复后跨页历史边界、连续点击 Undo/Redo 的 busy 门禁与失败提示。
