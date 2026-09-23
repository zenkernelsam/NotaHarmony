# Phase 645 — 原版页面管理面板（页总览 / content manager）

日期：2026-09-23 · 提交：见本节末 · 依据 ADR-0612

## 目标

补齐原版编辑器顶栏第一项的页面管理面板入口：原版 `x90.g` → `fh2`
→ `gs8(z,2)` 渲染 `content_manager_toggle`，打开 `qd2` 页总览面板
（标题 "Pages"，过滤枚举 `nd2` = ALL/BOOKMARKS/NOTES）。Harmony
此前没有页缩略图栅格表面。

## 实现

### 入口（原版顶栏首项对齐）

- `EditorToolbar`：`Row` 首项新增 ▦ 按钮，a11y =
  `cd_pages_panel_toggle`，位于工具循环与 undo/redo 之前；
  门禁与兄弟入口一致（photoImportLease / pageOperationBusy /
  historyPending）。

### 面板组件 `PageOverviewPanel`

- 标题 `pages_panel_title`（= "Pages"/"页面"）+ 三枚过滤 chip
  （`pages_filter_all/bookmarks/notes`，序镜像 `nd2`）+ 显式 ✕
  关闭（`cd_pages_panel_close`）。
- `Grid` 4 列缩略图：`ThumbnailRenderer` 自持实例，串行 Promise
  链逐张渲染；cell key 携带页身份 + 几何/模板字段 + `thumbRevision`
  + 主题，`@Watch` 驱动重渲染；`PixelMap` 由 cell 自持并在消失/
  换代时 `release()`，面板消失时 `renderer.dispose()`，迟到结果
  按 generation/disposed 丢弃并释放。
- 当前页 accent 描边；`page.bookmarked` 页渲染 🔖 角标（a11y
  `bookmark_page`）；点击 cell → `onJumpToPage`（沿用既有页跳
  门禁）；过滤为空渲染 `pages_panel_empty`。
- NOTES 过滤：`StrokePersistence.getPageElementCounts`（
  `page_element_snapshot` 按 `page_id` GROUP BY 计数），行数 > 0
  判定「有内容」；修订种子变化时重新拉取。

### `NotePage` 接线

- `@State showPageOverview` / `pageContentVersion`；
  `onUndoRedoChanged` 中 `pageContentVersion++`（任何可撤销内容
  变更 → 缩略图与 NOTES 计数刷新）。
- `bindSheet(showPageOverview, buildPageOverview(), { LARGE,
  showClose:false })`；`onJumpToPage` 复用
  pageLoading/pageOperationBusy/historyPending/pageStructureLease
  门禁；`onRequestClose` 关面板。

### 持久层

- `StrokePersistence.getPageElementCounts(noteId)`：初始化守卫 +
  `WHERE note_id=? GROUP BY page_id` + `finally` 关 ResultSet。

## 差异登记

多选（`isSelecting`/`selectedPageIds`/`tfh`）与页内搜索
（`isSearchActive`/`searchMatchingPageKeys`）未实现，登记 ADR-0612
差异表；侧栏形态以 LARGE 半屏 Sheet 对齐。

## 验证

- `d05-original-page-overview.mjs`：47 断言全绿。
- 全量 Desktop Replay：530/530 全绿。
- `hvigor clean` 后 `note@ohosTest` + `note@default` 双 HAP
  构建成功；无新增 ArkTS 错误（修复 `@Watch` 只能装饰属性的
  编译错误）。
- 未运行模拟器/真机/Hypium。

## 提交

`见本节首行`（双 HAP clean + 530/530 后提交）。
