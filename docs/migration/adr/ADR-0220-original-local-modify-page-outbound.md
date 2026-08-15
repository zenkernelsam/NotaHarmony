# ADR-0220：本地页面重排写原版 `MODIFY_PAGE` 单页 relocation

## 状态

Accepted，2026-08-16。

## 背景

页面重排此前只改写 `page_info.page_index` 并追加 Harmony `REORDER_PAGES` 历史。对已建立原版页面身份与
位置树的笔记，这会让本地数组顺序离开原版 page CRDT；后续同步、重开或远端 operation 到达时可能跳回、
分叉或因 `ORIGINAL_PAGE_ORDER_DIVERGED` 被拒绝。

原版 1.0.3 的 `q0 → be2 → u5j.s → r0j/egh` 证明：一次页面拖动生成一个 payload type 4
`MODIFY_PAGE`，pages vector 只含被拖页，field 1 是始终存在的 `SeqMove` table；移到根时仅 target 为空。

## 决策

1. `NotePage` 调用重排时显式传递 `selectedPageId`；Undo/Redo 继续传递同一 `action.pageId`。不能从相邻交换的
   before/after 猜测被移动的是哪一页。
2. `planOriginalPageReorder()` 要求 current/requested 成员唯一且完全相同；移除明确 moved page 后，其余顺序必须
   完全相同。否则请求不是可证明的单页 relocation，写前拒绝。
3. 最终 index 0 写“存在但 target-null”的 `SeqMove`；其余位置以最终前驱页的当前 winning position 为 target。
   不使用前驱页的初始 CREATE_PAGE SeqId 代替当前位置。
4. `OriginalModifyPagePayloadEncoder` 只写 pages + move，保持 background/bookmark 缺省，并拒绝空、超限、重复或
   非法 SeqId。
5. `persistOriginalPageReorder()` 分配原版 operation identity、包装完整 `uq9`、调用生产
   `OriginalModifyPageOperationApplier`，再验证 materialized order 与 CRDT visible order 都精确等于请求顺序。
6. 通过验证后追加 `OpType.ORIGINAL_MODIFY_PAGE = 77`、完整 envelope 和 `uploadImmediately=true`；同一外层事务再
   追加既有 NPG `REORDER_PAGES` history companion。
7. 只要笔记含原版页面身份，就不得在缺 moved identity、身份覆盖不完整、当前顺序不对齐或 reducer 结果不一致时
   静默降级成 Harmony-only 排序；事务必须回滚。完全没有原版页面身份的 Harmony legacy 笔记保留原有排序路径。
8. `PersistentHistory.isOriginalOutboundCompanion()` 忽略 type 77，使无 history 的出站行不切断本地 Undo 栈。
   边修边审同时发现 type 74/75 RichText style 出站行也遗漏于该白名单，本阶段一并补齐并加 fixture。

## 结果

- 本地页面顺序、原版位置树、待上传 operation 与持久 Undo/Redo 在同一 SQLite transaction 内收敛。
- 首位移动保留原版 `SeqMove` presence；连续移动引用最新 winner，不会锚到已输掉的旧 position。
- 相邻交换不再依赖有歧义的数组差异推断。
- 无法证明正确性的原版笔记重排会 fail closed，不会制造更隐蔽的 CRDT 分叉。

## 代价与后续

当前 UI 仍只提供相邻移动；writer/planner 已能表示任意单页 relocation，后续拖拽 UI 可复用相同接口。批量多页
move 虽是原版协议能力，但在没有明确 UI identity 与 Undo 语义前不开放。本阶段仅静态、fixture、Node/SQLite
与 HAP 构建验证；多端并发和真实上传需设备/服务端联调。

原版线性证据见
`docs/migration/evidence/original-local-modify-page-outbound-jadx-2026-08-16.md`。
