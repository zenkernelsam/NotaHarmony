# Phase 646 — 页面管理面板页内搜索

日期：2026-09-23 · 依据 ADR-0613 · 接续 Phase 645（面板本体）

## 目标

补齐原版 `qd2` 页总览的页内搜索：`r22` case 24 渲染
`content_manager_search`（"Search"）行 → `de2.l()` 置
`isSearchActive`；`de2.s(query)` 经 `xd9.d` 流产出
`searchMatchingPageKeys`；`qd2.c()` 在 nd2 过滤之后按
`isSearchActive && !isBlank(query)` 与命中页键求交。

## 实现

### 持久层

- `StrokePersistence.searchPageIdsWithText(noteId, query)`：
  `search_item` 表（既有全文索引，page 级粒度）
  `WHERE note_id=? AND page_id IS NOT NULL AND folded_text LIKE ?
  ESCAPE '\'` → `DISTINCT page_id` 集合；`foldSearchText` 规范化 +
  `escapeSearchLike` 转义；空白 query 短路返回空集；
  初始化守卫 + `finally` 关 ResultSet。

### 面板（`PageOverviewPanel`）

- 头部新增 🔍 开关（`cd_pages_panel_search`）→ `searchActive`；
  关闭时清 `searchQuery`/`matchingPageIds`。
- 激活时渲染 `TextInput`（`pages_panel_search_placeholder`，
  a11y `pages_panel_search`）；`onChange` → `runSearch()`，
  `searchGeneration` 计数丢弃乱序/迟到结果。
- `visibleItems()` 尾段对齐 `qd2.c()`：`searchActive && 非空白
  query` 时与 `matchingPageIds` 求交；命中集未回为空集 →
  fail-closed 空列表（与原版 `qd2.i` 初始空集一致）。

### 资源

- base/zh_CN 各新增 `pages_panel_search`、`cd_pages_panel_search`、
  `pages_panel_search_placeholder`。

## 差异登记

原版 query 走 `xd9.d` 流（疑似 debounce）；Harmony onChange 直发
轻量 SQL + generation 防乱序，行为等价无节流（ADR-0613）。

## 验证

- `d05-original-page-overview-search.mjs`：24 断言全绿。
- 全量 Desktop Replay：531/531 全绿。
- `hvigor clean` 后 `note@ohosTest` + `note@default` 双 HAP
  构建成功；无新增 ArkTS 错误。
- 未运行模拟器/真机/Hypium。

## 提交

见 git log（双 HAP clean + 531/531 后提交）。
