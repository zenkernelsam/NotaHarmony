# Phase 650 — 面板页操作不移动查看页 + 批量 Duplicate 锚定

日期：2026-09-23 · 依据 ADR-0617 · 关闭 ADR-0614 登记的导航差异、
修正 Phase 648 批 Duplicate 的交错插入

## 目标

两条原版语义对齐：

1. 面板发起的页操作不移动查看页——`ae2`/`e2` 全文零 `qd2`
   引用（`currentPageIndex` 从不被页操作改写）。
2. 批量 Duplicate 的副本**成组**插在选中集末页之后（`de2.j`
   反向扫描页表取最后一张选中页为 `m1d.c0` 单一锚点）。

## 原版证据

- `ae2.java`/`e2.java`：`qd2` 0 命中——Copy/Cut/Delete/
  Duplicate/Clear/Bookmark/Paste 均无 UiState 写。
- `de2.j(list)`：`listIterator(list2.size())` 反向遍历页表，
  返回首个属于选中集的页（页序上最后一张选中页）。
- `fd2` case3 → `zd2(de2, cxc, 0)`：`new zd2(` 全源仅 fd2 两处
  实例化 + `add_page` 字符串仅 n9j 引用——加页仅 cell 菜单可达；
  `invokeSuspend` 未反编译，不导航按姊妹变体 v1(rotate) 推定
  （ADR-0617 登记残余歧义）。

## 实现

### `NotePage.addPageAt`

- 删除 `currentPageIndex = insertIndex` 与前置的
  `findIndex(assignedPage)`（该行在 splice 前执行，恒得 -1，
  构成瞬时无效索引——顺带清除）。
- 发布后 `selectPageById(selectedBefore)`；
  `selectedPageIdAfter = selectedBefore`（redo 同样不跳页）。

### `NotePage.duplicatePageAt` / `pasteCopiedPageAt`

- 操作前捕获 `selectedBefore`（当前页 pageId）；物料化后按页键
  锚回——插入在查看页之前时索引顺移、之后时原位，两种情形
  查看页都不变。
- `pasteOneCopiedPage` 移除逐页 `selectPageById(pasted.pageId)`；
  批粘贴结束统一锚定一次。

### 批量 Duplicate（`dispatchPageSelectionAction`）

- 升序 `indicesOf()` 遍历，`capturePageCopyPayload` 逐页捕获，
  `pasteOneCopiedPage` 从 `indices[last]` 起顺次后插——
  `{1,3}` in `[1,2,3,4]` → `[1,2,3,1',3',4]`（原版）而非
  `[1,1',2,3,3',4]`（旧 Harmony）。
- 复用粘贴管线（`insertCopiedPage` + `commitCopiedPageContent`）
  与 duplicate 在持久层同源（`commitOriginalDuplicatePageContent`）。

## 差异登记（ADR-0617）

- `zd2` v0 内部不透明：不导航为推定（pager keyed-vs-raw-index
  不可静态判定）；若原版为 raw-index，「查看页之前插入」会使
  画布顺移一页——Harmony 取 identity 语义，与 delete 一致。
- 批量历史仍逐页记帐（复合 action 登记）。

## 验证

- 专项 Replay `d05-original-panel-ops-viewed-page.mjs`：13/13。
- 更新 pins：`d04-original-add-page-anchor` 26/26、
  `d04-original-page-duplicate` 82/82、
  `d02-page-operation-disposal-bound` 15/15、
  `d05-original-page-multiselect` 32/32、
  `d05-original-page-context-menu` 20/20。
- 全量 Desktop Replay：535 项全绿。
- `note@default` / `note@ohosTest` 双 HAP 构建 0 错误。
- 未启动模拟器/真机/Hypium。
