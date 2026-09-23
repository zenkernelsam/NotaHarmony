# 原版页面管理面板（content manager / 页总览）证据 — JADX 静态提取

日期：2026-09-23 · 来源：`decompiled_1.0.3`（Notability Android 1.0.3）· 仅静态证据，无运行时验证。

## 1. 顶栏入口（首位）

`x90.g` 组装编辑器顶栏项，顺序为：

1. `new fh2(function0, z)` —— `fh2` 内部 `gs8(z, 2)` → `gs8` case 2 渲染
   `content_manager_toggle` 图标按钮（`nti.e` + `pz2.g`/`pz2.h` 开/关态），
   a11y 文案 `feature_note__content_manager_toggle_description`；
2. 随后才是 `new p9f(wrdVar, i8)` undo/redo 图标块；
3. 尾部 `ke1` 项（含 Share、AI、youtube 等 flag 门禁图标）。

⇒ 页面管理面板开关是**顶栏第一项**，位于撤销/重做之前。

## 2. 面板 VM：`qd2`

`qd2.java` `UiState.toString()` 字段：

```
currentPageIndex, pages, thumbnails, selectedFilter,
isSelecting, selectedPageIds, isSearchActive, searchQuery,
searchMatchingPageKeys
```

⇒ 面板状态包含：当前页、页列表、缩略图、选中过滤器、多选模式与
选中页集合、页内搜索状态。

## 3. 过滤枚举：`nd2`

```java
nd2 nd2Var = new nd2("ALL", 0);
nd2[] nd2VarArr = {nd2Var, new nd2("BOOKMARKS", 1), new nd2("NOTES", 2)};
```

`n9j`（约 2212–2220 行）把三个序数映射到字符串资源：

- `feature_note__content_manager_filter_all`
- `feature_note__content_manager_filter_bookmarks`
- `feature_note__content_manager_filter_notes`

⇒ 面板顶部三枚过滤 chip，序固定为 All / Bookmarks / Notes。

## 4. 其余面板文案（`res/values/strings.xml`）

- `feature_note__content_manager_title` = **"Pages"**（面板标题）
- `feature_note__content_manager_close_description`（关闭按钮 a11y）
- `ui_pageselection__no_pages`（过滤为空的占位文案）
- `ui_pageselection__select_all` / `deselect_all`（多选工具条，见 §5）

## 5. 关联但未本轮实现的表面

- 多选：`de2.l()`/`de2.u()` 进入/退出选择模式，`fd2` case 0 为缩略图
  点选切换，`tfh` 为多选工具条（含 select_all/deselect_all）。
- 页内搜索：`qd2.isSearchActive`/`searchMatchingPageKeys`。
- 缩略图上的页操作入口：`vc2` 页上下文菜单（已由 PageManagerBar
  覆盖其主要项）。

## 6. Harmony 对齐点（Phase 645）

- `EditorToolbar` 顶栏首项 ▦ 开关（undo/redo/工具之前）；
- `PageOverviewPanel`：标题 + 三过滤 chip（nd2 序）+ 4 列缩略图
  栅格（`ThumbnailRenderer` 串行渲染）+ 当前页高亮 + 书签角标 +
  空态 + 显式关闭；
- `StrokePersistence.getPageElementCounts` 提供 NOTES 过滤的
  「页面内容非空」判定；
- 多选与页内搜索登记为后续 Phase（ADR-0612）。
