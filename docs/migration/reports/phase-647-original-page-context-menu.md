# Phase 647 — 页面管理面板 cell 上下文菜单

日期：2026-09-23 · 依据 ADR-0614 · 接续 Phase 645/646

## 目标

补齐原版页总览 cell 的上下文菜单：原版 `n9j` 菜单（Add page /
Cut / Copy / Paste? / Duplicate / Rotate Page? / Clear Page /
Delete）经 `fd2` 按页键分发页操作，不改 `qd2.currentPageIndex`。

## 实现

### 面板（`PageOverviewPanel` / `PageOverviewCell`）

- cell 增加 `bindContextMenu`（`ResponseType.LongPress`）→
  `buildCellMenu()` 按原版序渲染 MenuItem。
- 门禁对齐原版：Paste ← `canPastePages`（剪贴板非空）；
  Rotate ← `rotatedOriginalPageInfo(page) != null`；Clear 仅当前页
  （画布信号管线 fail-closed）；Create Template 上游 flag 关闭缺席。
- 新增 `onPageAction(pageIndex, action)` 回调与 `canPastePages` prop。

### `NotePage`

- `dispatchPageContextAction(pageIndex, action)`：`runPageOperation`
  门禁下分发 add/cut/copy/paste/duplicate/rotate/delete；clear 仅
  当前页 `clearPageSignal++`。
- 页操作全部参数化：`addPageAt` / `deletePageAt` /
  `copyPageAt` / `cutPageAt` / `pasteCopiedPageAt` /
  `duplicatePageAt` / `rotatePageAt`；既有 `*CurrentPage` 入口委托
  `…At(currentPageIndex)`，行为不变。
- 非当前页内容经 `persistedPageSnapshot` / `persistedPageCopyPlan`
  从 `page_element_snapshot` 重建（`loadElements` 同形 +
  `originalGroupGraphForPageCopy` 组子图）。
- 选中态：删除/旋转非当前页不导航（`selectedBefore/After` 保持
  当前页 id），对齐原版「面板操作不动 currentPageIndex」。

## 差异登记

长按触发（vs 原版 ⋯ 下拉）、Clear 仅当前页、Add/Duplicate/Paste
后导航到新建页、fd2 case0 多选未实现——全部登记 ADR-0614。

## 验证

- `d05-original-page-context-menu.mjs`：20 断言全绿。
- 全量 Desktop Replay：532/532 全绿。
- `hvigor clean` 后 `note@ohosTest` + `note@default` 双 HAP
  构建成功；无新增 ArkTS 错误。
- 未运行模拟器/真机/Hypium。

## 提交

见 git log（双 HAP clean + 532/532 后提交）。
