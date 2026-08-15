# Phase 243 修复总结：原版本地页面重排 `MODIFY_PAGE` 出站

## 本阶段目标

修复页面重排只写 Harmony `page_index + REORDER_PAGES`、没有生成原版 payload type 4
`MODIFY_PAGE` 的协议分叉。目标是让本地页序、原版 Page SeqId／position winner、待上传 operation 与持久
Undo/Redo 在同一事务中保持一致；任何无法证明正确性的原版笔记重排必须写前拒绝。

## 原版结论

- `q0.java:482-490` 从 `DragPageResult.fromIndex` 取得明确被拖页面身份，并传递 `toIndex`。
- `be2.java:91-99` 用 singleton Page SeqId 调用 `u5j.s()`，一次单页拖动生成一个 `MODIFY_PAGE`。
- `r0j.java` 的 `ge8` writer：field 0 是 12-byte Page SeqId vector，field 1 是 `lxc SeqMove`，field 2/3
  分别为 background/bookmark。
- `egh.java:21-30` 证明移到根时仍创建 `SeqMove` table，只省略其 nullable target；不能省略整个 move field。
- `v69 → ko → twc → bl2/al2` 为移动页建立新 position，并以稳定页面身份为 key、operation ID 为 winner；旧
  position 保留为后续因果锚点。

完整证据见
`docs/migration/evidence/original-local-modify-page-outbound-jadx-2026-08-16.md`。

## 已完成修复

1. 新增 `OriginalModifyPagePayloadEncoder.ets`：
   - 写原版 `ge8.pages + lxc SeqMove`；
   - target-null 时仍保留 `SeqMove` table；
   - background/bookmark 保持缺省；
   - 拒绝空、超过 10000、重复或越界 Page SeqId。
2. 新增 `OriginalPageReorderPlanner.ets`：
   - 要求 current/requested 成员唯一且完全相同；
   - 必须显式提供 `movedPageId`；
   - 移除该页后其余顺序必须完全一致，证明请求是单页 relocation；
   - 最终首位映射 root，其他位置映射最终前驱页。
3. `NotePage.moveCurrentPage()` 传递真实 `selectedPageId`；Undo/Redo 继续使用同一 `action.pageId`。相邻交换不再
   从 before/after 猜测移动侧。
4. `OriginalPagePersistence.persistOriginalPageReorder()`：
   - 只接受完整且当前对齐的原版页面身份／位置状态；
   - moved page 使用稳定 Page SeqId；
   - predecessor 使用**当前 winning position**，不会锚到已输掉的旧 CREATE_PAGE position；
   - 分配 operation identity、包装完整 `uq9`、调用生产 `OriginalModifyPageOperationApplier`；
   - reducer 后同时验证 `page_info` 与 original visible order 精确等于 requested order；
   - 追加 `uploadImmediately=true` 的完整 type-4 envelope。
5. `PageRepositoryImpl.reorderPages()` 对任何含原版页面身份的笔记走上述严格路径；缺 moved identity、覆盖不完整、
   当前顺序分歧、非单页 relocation 或 reducer 结果不一致均整事务回滚，不再静默写 Harmony-only 顺序。完全没有
   原版页面身份的 legacy Harmony 笔记保留原路径。
6. 新增 `OpType.ORIGINAL_MODIFY_PAGE = 77`；同一外层事务在原版出站行之后追加既有 NPG
   `REORDER_PAGES` history companion。原版 reducer 推进的 structure revision 也被 companion 严格复核。
7. `PersistentHistory.isOriginalOutboundCompanion()` 忽略 type 77，防止无 history 的上传行切断本地 Undo 栈。
8. 更新 ADR-0082 的历史边界，明确 local MODIFY_PAGE/reorder 已由 ADR-0220 闭环。

## 边修边审额外捕获的问题

检查 `isOriginalOutboundCompanion()` 时发现 Phase 141 已生成的 RichText type 74
`ORIGINAL_MODIFY_TEXT_STYLE` 与 type 75 `ORIGINAL_MODIFY_PARAGRAPH_STYLE` 同样未进入透明白名单。Group Paste
中的这些出站行没有 history，可能把紧随其后的 `ORIGINAL_CLIPBOARD_PASTE` companion 与此前 Undo 栈错误分段。
本阶段一并补齐 type 74/75，并扩展 `PersistentHistory.test.ets` 锁定三类 companion 均不产生 legacy segment。

## Fixture 与 replay

- 新增 `OriginalModifyPagePayloadEncoder.test.ets` 并注册进 `List.test.ets`，覆盖：
  - singleton Page SeqId + 显式 predecessor round-trip；
  - 存在但 target-null 的 root `SeqMove`；
  - 相邻交换中显式 dragged identity 的两种不同解释；
  - root planning、非单页 mutation、成员变化、no-op、空／重复 payload 拒绝。
- 新增 `d02-local-modify-page-outbound.mjs`，输出：
  `localModifyPage=type4-single-drag-identity-winning-predecessor-root-undo-redo-history-transparent-rollback`。
- 专项同时验证：
  - 原版 `q0/be2/u5j/r0j/egh` 线性证据；
  - 二进制 pages vector、嵌套 move 与 target-null presence；
  - 连续 move 引用 predecessor 最新 winner；
  - PUSH/UNDO 同页 relocation；
  - type-4 行对 history 透明；
  - reducer 后故障完整回滚。
- 既有 `d02-modify-page-move.mjs`、local CREATE_PAGE、grouped history、Group Paste RichText styles 与 ArkTS
  build contracts 专项全部通过。
- 全量桌面 replay：`REPLAY_FILES=228 FAILED=0`。

## 构建与静态验证

- `git diff --check`：通过；仅有项目既有 LF→CRLF 提示。
- `hvigorw clean --no-daemon`：`BUILD SUCCESSFUL in 1 s 749 ms`。
- clean 后 `note@ohosTest` 非增量 HAP：`OhosTestCompileArkTS` 实际执行，
  `BUILD SUCCESSFUL in 7 s 324 ms`。
- 同一次 clean 后 `note@default` 非增量 HAP：Native Ninja、`CompileArkTS` 与 PackageHap 全部通过，
  `BUILD SUCCESSFUL in 44 s 969 ms`；输出仅有项目既有 exception-handling/deprecated warning。

## 决策与文档

- 新增 `ADR-0220-original-local-modify-page-outbound.md`，固化单页 relocation、winning predecessor、root
  SeqMove presence、生产 reducer、fail-closed 与双日志事务决策。
- 新增 `original-local-modify-page-outbound-jadx-2026-08-16.md`，记录原版操作生成、FlatBuffer writer、nullable
  SeqMove 与 position winner 证据及 SHA-256。
- 新增专项 replay，将原版证据、Harmony 生产接线、fixture、历史透明与 SQLite 原子回滚纳入持续回归。

## 尚未执行/后续

- 未启动设备、模拟器、虚拟机、真机或 Hypium。
- 真机需集中验证：首位／末位移动、连续快速 Undo/Redo、重开后页序、缩略图选中态、多端并发 move、上传 ACK
  与远端重新下载后的 CRDT 收敛。
- 当前 UI 仍只提供相邻移动；planner/writer 已能承载任意单页 relocation。原版批量 pages move 暂不开放，直到有
  明确 UI identity 与 Undo 语义。
- Goal 保持 active，继续边修边补审。T-042 APK 版本追踪仍严格留在最终阶段；完成时写独立 Report，并按用户约定
  归纳进 Wiki／技术文档／API／新手入门，入门文档说明其功能、入口、阅读顺序与新增 APK 后的使用流程。
