# Phase 716：原版页选计数标签 + 默认笔记题资源对齐

字符串族尾部审计（`ui_pageselection__`/`data_library_state__`/
`ui_composeutil__`）发现两处可移植小缺口：

## 原版证据

- `p7j.java:663`/`951`：`ui_pageselection__x_of_y_selected`
  （"%1$d of %2$d selected"）渲染于 `tfh` 页选工具条动作按钮旁，
  分子=选中数、分母=`list.size()`（过滤后列表）。
  （`no_pages`/`select_all`/`deselect_all` 已随页选工具条移植。）
- `data_library_state__default_note_title` = "New Note"：
  `id7:1172` 建篇默认题、`bib:43` 库行兜底、`e5j:325`/`ksh:935`
  显示兜底——原版全走资源串。Harmony 已有等价资源
  `untitled_note`="New Note"，但 `ImportDetailsSheet:345` 散落
  `'Untitled'` 字面量（文案不符且不可本地化）。
- `ui_composeutil__error_unable_to_open_link`（cq:2322/2362/2403
  链接打开失败 toast）已有 `link_open_failed` 覆盖——无缺口。

## 实现

- `PageOverviewPanel` 选择工具条：chips 滚动区前固定
  `pages_x_of_y_selected` 计数标签（`$r` 双参格式，
  分母 `visibleItems().length` 对齐 `list.size()`）。
- `ImportDetailsSheet`：`'Untitled'` → `$r('app.string.untitled_note')`。
- 新增 `pages_x_of_y_selected`：en "%d of %d selected"、
  zh "已选 %d/%d 页"（沿用 `share_range_selected` 串规约）。

## 验证

- `d02-original-page-selection-count.mjs`（16 断言：原版两渲染位/
  默认题串/面板计数/布局/字面量消除/双 locale/ADR+证据）。
- 全套件重跑、双 HAP 构建通过后记录于修复总纲。
