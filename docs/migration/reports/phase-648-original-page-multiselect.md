# Phase 648 — 页面管理面板多选模式

日期：2026-09-23 · 依据 ADR-0615 · 接续 Phase 645/646/647

## 目标

补齐原版 content manager 的多选表面：`qd2.isSelecting` /
`selectedPageIds` + `tfh` 选择工具条 + `dg2` 多页剪贴板。

## 原版证据

- `fd2` case0：`selectedPageIds` 成员切换（`ys2.K`/`ys2.G`，仅写
  字段 5）；`s8` case1 = cell 溢出菜单 "Select" 项。
- `de2.u()`：掩码 463 一次复位 isSelecting/selectedPageIds/
  isSearchActive。
- `n9j` function9 case2 Select all = `qd2.c()` 过滤全集；case3
  Deselect all = 清空 + `u()`。
- `n9j` tc2 7-case：Copy(0)+u() / Duplicate(1) / Delete(2)+u() /
  Cut(3)+u() / Paste(4) / Bookmark(5) / Clear(6)，参数
  `au1.T1(selectedPageIds)`。
- `de2.m~r`：空选中集 fail-closed + MODEL 日志，非空经 ae2 v0..5
  批应用（`x82.I` 记帐通道）。
- `dg2` = CopiedPagesData(ops:ArrayList, pageCount)：多页剪贴板。

## 实现

### `OriginalPageClipboard`

- `copiedPages: CopiedPagePayload[]` 有序多页记录；
  `storeCopiedPage`/`storeCopiedPages`/`copiedPagePayloads`/
  `hasCopiedPage`/`clearCopiedPage` 全套接口。

### `PageOverviewPanel`

- `@State selecting` + `@State selectedPageIds`；
  `toggleSelectPage`（fd2 case0 对齐：并入即进入选择态）。
- `exitSelection()`：de2.u() 三字段复位（selecting/selectedPageIds/
  searchActive）。
- `selectAllVisible()`：装载 `visibleItems()` 过滤全集（n9j case2）。
- 选择工具条：Select all/Deselect all 单钮切换 + Copy/Duplicate/
  Delete/Cut/Paste?/Bookmark/Clear? + Done；`dispatchSelection`
  按升序页序上抛 `onSelectionAction`，并按原版在
  copy/delete/cut 后 `exitSelection()`。
- cell：`selecting`/`checked`/`onToggleSelect` props；选择态 tap=
  成员切换、缩略图勾选圈；上下文菜单末项 "Select"。
- `onPagesChange` 裁剪已消失页键。

### `NotePage`

- `dispatchPageSelectionAction(action, pageIds)`：`runPageOperation`
  门禁下批量执行；页键→索引动态重解析（`indicesOf()`），变序操作
  （cut/delete/duplicate）降序执行。
- `capturePageCopyPayload(pageIndex)`：拷贝负载构造提取（画布
  capture / `persistedPageCopyPlan` 持久层重建）。
- `togglePageBookmarkAt(pageIndex)`：PAGE_BOOKMARK 通道参数化。
- `pasteCopiedPageAt`：`copiedPagePayloads()` 逐条经
  `pasteOneCopiedPage` 顺次插运行锚点后。
- 批粘贴锚点 = 选中集末页（原版 e2 v16 位序不可静态判定，登记）。

## 差异登记（ADR-0615）

- 批量 Clear 仅「选中集恰为当前页」可执行；其余 fail-closed
  （非当前页清空需持久层删除管线）。
- 批量操作逐页记帐（每页一条撤销动作），原版为 ae2 单批。
- tfh 形态落为横向滚动 chip 行。

## 验证

- 专项 Replay `d05-original-page-multiselect.mjs`：31/31。
- 全量 Desktop Replay：533/533 全绿。
- `note@default` / `note@ohosTest` 双 HAP 构建 0 错误。
- 未启动模拟器/真机/Hypium。
