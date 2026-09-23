# ADR-0603：原版页级剪切/拷贝/粘贴（Page Cut / Copy / Paste）

- 状态：Accepted
- 日期：2026-09-23
- 阶段：Phase 636
- 证据：`docs/migration/evidence/original-page-cut-copy-paste-jadx-2026-09-23.md`

## 背景

原版内容管理器单页菜单（`n9j`）含 Cut / Copy / Paste 三项，Harmony 在
Phase 635 落地 Duplicate 后仍缺这组页剪贴板动作。原版实现（`ae2`
变体 2/3 + `mg2.b`）语义清晰：Copy 把 `u5j.e` 序列化流存入进程级页
剪贴板；Cut 在 Copy 基础上追加与 Delete Pages 相同的删除 op；Paste
在剪贴板非空时出现，经统一剪贴板应用器（`lg2`/`m1d.c0`）在锚点重放。

## 决策

1. **进程级页剪贴板**：新建 `rendering/OriginalPageClipboard.ets`
   （`copiedPage` 单例 + `CopiedPagePayload`）。与原版 `mg2.b` 同为
   内存态——进程死亡即失，不持久化。
2. **剪贴板存物化负载而非 op 流**：`CopiedPagePayload` 携带
   `background`（`duplicatedOriginalPageBackground` 取出的有效 nz9，
   已含 `l7j.c` 单页折叠）、`bookmarked` 与 `plan`（`PageCopyPlan`：
   元素快照 + `originalGroupGraphForPageCopy` 页内组子图）。粘贴经
   `commitOriginalDuplicatePageContent` 转码重放，实体仍获全新
   `mappedIds` 身份——对外语义与原版 op 流转码一致。
3. **Paste 复用 DUPLICATE_PAGE 伴随 op**：原版 Paste 与 Duplicate
   经同一 `m1d.c0` 通道产出同型 op 流，日志无法区分；Harmony 同样
   共用 `OpType.DUPLICATE_PAGE` 伴随 + `DuplicatePageAction`
   （`sourcePageId` 记锚点页），undo 隐藏 / redo 恢复语义一致。
4. **Cut = Copy + 既有 DELETE_PAGE**：`cutCurrentPage` 先
   `copyCurrentPage` 再走既有 `deleteCurrentPage`——与原版"序列化
   + `de2.i` 删除 ops"的日志形状一致，撤销恢复页内容不变。
5. **菜单顺序与可见性**：PageManagerBar 菜单按原版顺序插入
   Cut、Copy，Paste 仅在 `canPastePage`（剪贴板非空且目标可行）时
   插入 Copy 与 Duplicate 之间。
6. **跨笔记限制（fail-closed）**：`mg2` 是应用级剪贴板，原版支持
   跨笔记粘贴。Harmony 图片元素引用按笔记链接的内容寻址资产行，
   跨笔记写页需补资产链接；本阶段允许**无图片页**跨笔记粘贴，含图
   页跨笔记 fail-closed 并 toast 提示。

## 后果

- 三个新菜单项（Cut/Copy/Paste）+ 局部化字符串；Paste 菜单项条件渲染。
- `PageRepositoryImpl` 抽取 `insertPageAfterAnchor` 共享体，Duplicate 与
  Paste 共用；`insertCopiedPage` 以剪贴板元数据取代活源页。
- `EditorHistoryBridge` 增 `captureCurrentPageCopyPlan` /
  `commitCopiedPageContent`；`PageCopyPlan` 为桥接侧计划类型，
  `pageCopyPlanToPastePlan` 在持久化边界显式重包（ArkTS 禁结构类型）。
- 后续项：含图页跨笔记粘贴需补资产链接行写入。
