# Phase 261 修复总结：原版 History Coalesce 页面域

## 基线与目标

- 基线提交：`6cc7ab5 fix(thumbnails): revalidate source revision`
- 目标：继续重放 `修复总纲2.md` 的 M2-R-07，严格参考原版 1.0.3 Undo/Redo coalesce 顺序，修复 Harmony
  在跨页历史恢复/极端快速切页时先形成跨页 group、随后 UI 静默只撤销顶部动作的问题，并复核同页 group 的
  durable 原子性。
- 本阶段不启动设备、模拟器、虚拟机、真机或 Hypium。

## 原版证据结论

- `vnf.f()/g()` 从活动栈顶临时选择相邻 `qnf`，只比较 track 与相邻 client timestamp；anchor 每纳入一项即
  更新，因此是 pairwise adjacent window。
- `pnf` 的 INSERT_TEXT、REMOVE_TEXT、CREATE_INK 窗口分别是 2 秒、2 秒、10 毫秒，边界为 inclusive。
- `qnf` 保存 undo/redo、coalesce track、timestamp 与 extras，没有 pageId。
- `tzc.R` 通过 editor owner `eof/dof` 持有 `vnf`；静态代码不能证明原版在 `vnf` 内按页面分栈。
- `vnf.a(List)` 保持 Undo 反向展平和 Redo 正向展平。Harmony 继续以独立 action identity 按同一方向逐项
  durable replay，不创建伪造的组合 actionId。

完整哈希、代码片段和架构边界见
`docs/migration/evidence/original-history-coalesce-page-domain-jadx-2026-08-17.md`。

## 实际修改文件

- `note/src/main/ets/rendering/UndoRedoManager.ets`
- `note/src/main/ets/ui/editor/NoteCanvasView.ets`
- `note/src/test/UndoRedoManager.test.ets`
- `docs/migration/replays/d02-original-history-coalesce-page-domain.mjs`
- `docs/migration/evidence/original-history-coalesce-page-domain-jadx-2026-08-17.md`
- `docs/migration/adr/ADR-0239-original-history-coalesce-page-domain.md`
- `docs/migration/adr/ADR-0003-append-only-snapshot-operation-log.md`
- `docs/migration/audit-2026-08/修复总纲.md`
- `docs/migration/audit-2026-08/修复总纲2.md`
- `docs/migration/reports/修复进展-2026-08-09.md`
- 本报告。

## 修复前真实缺陷

Harmony 已拥有全笔记持久历史和 action `noteId/pageId`，但旧 `peekGroup()` 只比较 track/time。页面内容由
`NoteCanvasView` 异步逐页加载，`saveHistoryGroup()` 又只能针对一个 pageId：

```text
manager 形成跨页 group
  -> UI isSinglePageElementGroup() 返回 false
  -> 继续落入单动作 handler
  -> 只施加/提交 group[0]
```

这会破坏原版“已选择的 coalesced group 是一次 Undo/Redo 命令”的原子语义。

## 实际修改

### Manager coalesce domain

`UndoRedoManager.peekGroup()` 在原版 track/time 判断之前增加相邻 action 的 `noteId + pageId` 精确相等条件。
任一 identity 改变立即停止 group；同页的 10ms/2s、inclusive 和 pairwise anchor 不变。

这是一条 Harmony 异步页面/持久恢复架构不变量，不伪称原版 `qnf` 有 pageId。也没有按 action type 过度限制
track，因为持久恢复的原版文本 mutation 会物化为 `PERSISTED_PAGE_MUTATIONS`，仍需合法携带文本 track。

### UI fail closed

`NoteCanvasView.performHistory()` 现在对所有 `group.length > 1` 先要求 `isSinglePageElementGroup()` 成功。
跨 note/page、页面结构动作或特殊复合动作若异常进入 group，命令直接拒绝并保持画布/栈不变；不再落入单动作
分支造成部分成功。

### 同页 durable 原子性复核

同页 group 继续执行：

1. flush 已排队 PUSH；
2. 在内存逐动作严格校验并捕获每个中间 snapshot；
3. `writeHistoryGroupLocked()` 在一个 SQLite transaction 中核对数据库来源、逐项推进 revision 并写原 actionId；
4. 全部 durable 成功后才 `commitUndoGroup/commitRedoGroup`；
5. 任一步失败 rollback 数据库、恢复执行前画布并保留原栈。

本阶段未重复重构该已存在且通过故障注入的事务结构。

## Fixture、ADR 与 replay

- `UndoRedoManager.test.ets`：新增跨 page、跨 note 截断，以及 page-domain Undo/Redo group 顺序 fixture。
- 新增 ADR-0239：记录原版 track/time 与 Harmony page-domain 的有意架构适配。
- 新增原版 JADX evidence，包含八个关键类 SHA-256。
- 新增 `d02-original-history-coalesce-page-domain.mjs`：`TOTAL=16 FAILED=0`。
- 相关 history/page/text/clipboard/Group/partial-eraser replay：`RELATED_REPLAY_FILES=20 FAILED=0`。
- `d02-grouped-history.mjs` 继续证明 Undo `c,b,a`、Redo `a,b,c`、第二步日志注入失败整组 rollback 和 source
  mismatch 拒绝。
- 全量桌面 replay：`REPLAY_FILES=246 FAILED=0`。

## 最终验证

- 修改中增量 `note@ohosTest`：`BUILD SUCCESSFUL in 6 s 490 ms`。
- `hvigorw --no-daemon clean`：`BUILD SUCCESSFUL in 1 s 736 ms`。
- 同一次 clean 后 `note@ohosTest`：`BUILD SUCCESSFUL in 7 s 19 ms`。
- 同一次 clean 后 `note@default`：`BUILD SUCCESSFUL in 31 s 522 ms`。
- `git diff --check` 通过；构建只有项目既有 ArkTS/deprecation 与未配置 signing warning。
- 未启动设备、模拟器、虚拟机、真机或 Hypium。

## M2-R-07 状态与设备验收

M2-R-07 的全笔记 note/page identity、页结构与 NOTE_BACKGROUND 动作、双预算、可观察淘汰、持久恢复、
coalesce 顺序、同页 grouped transaction、来源核对和失败不跳步等已知静态架构项现闭环。仍需设备验证：

- 同页快速连续书写的一次 Undo/Redo 粒度；
- 历史顶部属于另一页时自动切页后完整施加；
- 连续点击 Undo/Redo、切页和编辑并发时 busy 门禁；
- 应用重启恢复后的跨页边界和失败提示；
- 画笔、擦除、变换、文本、剪贴板、Group/Shape、z-order、页结构和纸张背景的完整设备矩阵。

## Goal 纪律

T-042 APK 版本追踪仍严格留到整个 Goal 最后。本阶段只登记延后约束，不创建版本追踪目录、不执行整包版本
diff；最终必须另写中文 Report，并把追踪文档/工具的用途、入口、阅读顺序及新版 APK decompile/diff 流程
归纳进 Wiki、技术文档、API 文档与新手入门。
