# ADR-0617 面板页操作不移动查看页 + 批量 Duplicate 锚定

- 状态：Accepted
- 日期：2026-09-23
- 关联 Phase：650
- 接续：ADR-0614（登记「面板内 Add/Duplicate/Paste 不动
  currentPageIndex」差异）、ADR-0615（批量操作）
- 证据：`docs/migration/evidence/original-panel-ops-viewed-page-jadx-2026-09-23.md`

## 背景

原版 content manager 的全部页操作（`ae2` 变体 0..5 与 `e2` Paste）
**从不写 `qd2.currentPageIndex`**——两个类文件对 `qd2` 零引用。
即面板内 Add/Duplicate/Paste/Copy/Cut/Delete/Clear/Bookmark 完成后
查看页保持不动；ADR-0614 已登记 Harmony「导航到新建页」的差异。

同时 `ae2` v5 的批 Duplicate 经 `de2.j` 计算**单一锚点**（页序上
最后一张选中页），`m1d.c0` 一次应用把全部副本插在该锚点之后；
Harmony Phase 648 的批 Duplicate 逐页插在各自源页之后（交错）。

## 决定

1. **不导航（identity-preserving 查看页）**：
   - `addPageAt`：删除 `currentPageIndex = insertIndex`（及其前置的
     `findIndex` 瞬时 -1 赋值），发布后 `selectPageById
     (selectedBefore)`；`AddPageAction.selectedPageIdAfter =
     selectedBefore` → redo 也不跳页。
   - `duplicatePageAt`：操作前捕获 `selectedBefore`，物料化后按
     页键锚回原查看页，不再 `selectPageById(duplicated.pageId)`。
   - `pasteCopiedPageAt`：循环外一次 `selectPageById
     (selectedBefore)`；`pasteOneCopiedPage` 不再逐页导航。
   - 底栏 "+" / Paste / Duplicate（Harmony 超集面，原版无对应入
     口）与 cell 菜单共用同一语义——原版唯一的加页/复制/粘贴
     入口就是面板。
2. **批量 Duplicate 锚定**（`de2.j` 对齐）：`dispatchPageSelection
   Action('duplicate')` 改为升序遍历选中索引，payload 经
   `capturePageCopyPayload` 捕获后以 `pasteOneCopiedPage` 顺次插
   在运行锚点（初值=选中集末页索引）之后——副本**成组**落在
   末页之后，保持源页序。锚点 ≥ 全部源索引，插入不位移未捕获
   源页，无需降序防护。
   - 单页 duplicate（cell 菜单）行为不变：`de2.j([x]) = x`。
   - 复用 `insertCopiedPage` + `commitCopiedPageContent`：与
     `duplicatePage` + `commitDuplicatePageContent` 在持久层同源
     （都汇到 `commitOriginalDuplicatePageContent` 转码）。
3. 撤销/重做的选中恢复沿用既有约定（undo→before / redo→after），
   不改 `applyPageHistory` 各分支。

## 与原版差异（fail-closed / 登记后续）

| 原版 | Harmony | 处置 |
|---|---|---|
| zd2 v0（add）内部未反编译；不导航按姊妹变体 v1 与面板语义推定 | 不导航 | 残余歧义登记：若原版 pager 为 raw-index 非 keyed，「在查看页之前插入」在原版会使画布顺移一页；Harmony 按页键锚定为 identity 语义（与 delete 一致），若后续 bytecode 证据表明为 raw-index 再调整 |
| undo/redo 不写 qd2（原始历史为 op 流回放） | Harmony undo→selectedBefore / redo→after 的既有约定保留 | 登记：undo 语义上是「回到受影响页」的 Harmony 约定 |
| ae2 v5 一次 c0 应用 → 一步撤销 | 批 Duplicate 逐页 DUPLICATE_PAGE action | 登记：批量历史合并需复合 action（同 ADR-0615/0616 表项） |

## 验证

- 专项 Replay：`d05-original-panel-ops-viewed-page.mjs` 13/13。
- 回归更新：`d04-original-add-page-anchor`（26/26）、
  `d04-original-page-duplicate`（82/82）、
  `d02-page-operation-disposal-bound`（15/15）、
  `d05-original-page-multiselect`（32/32） pins 更新为新语义。
- 全量 Desktop Replay 全绿。
- `note@default` / `note@ohosTest` 双 HAP 构建 0 错误。
