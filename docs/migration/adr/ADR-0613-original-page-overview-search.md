# ADR-0613 原版页面管理面板页内搜索

- 状态：Accepted
- 日期：2026-09-23
- 关联 Phase：646
- 接续：ADR-0612（页面管理面板本体）
- 证据：`docs/migration/evidence/original-page-overview-search-jadx-2026-09-23.md`

## 背景

原版 `qd2` 页总览面板带页内搜索：`de2.l()` 置 `isSearchActive`，
`de2.s(query)` 把查询推进 `xd9.d` 流，结果写回
`searchMatchingPageKeys`；`qd2.c()` 在 nd2 过滤之后按
`isSearchActive && !query.isBlank` 与命中页键求交。面板行项
`content_manager_search`（"Search"）是激活入口。

## 决定

1. `PageOverviewPanel` 头部新增 🔍 开关（a11y
   `cd_pages_panel_search`），对齐原版 `content_manager_search`
   行 → `searchActive`；关闭时清 `searchQuery` 与命中集。
2. 激活时渲染 `TextInput`（placeholder
   `pages_panel_search_placeholder`，a11y `pages_panel_search`）；
   `onChange` → `runSearch()`，`searchGeneration` 计数丢弃乱序结果。
3. `visibleItems()` 尾段对齐 `qd2.c()`：`searchActive &&
   query.trim()非空` 时仅保留 `matchingPageIds` 中的页；命中集未
   回时为空集 → fail-closed 空列表（原版 `qd2.i` 初始即空集，
   语义一致）。
4. 持久层新增 `StrokePersistence.searchPageIdsWithText`：复用既有
   `search_item` 全文索引（`page_id` 粒度），
   `foldSearchText` 规范化 + `escapeSearchLike` 转义 +
   `DISTINCT page_id`。
5. 空白 query 直接短路返回空集，不发 SQL（对齐 `lvd.E0` 分支）。

## 与原版差异

| 原版 | Harmony | 处置 |
|---|---|---|
| query 经 `xd9.d` 流（疑似 debounce）异步产出命中集 | onChange 直发轻量 SQL + generation 防乱序 | 行为等价；无节流，登记差异 |
| 命中键为 `z5c.Z(cxc)` 页键 | 直接用 `page_id` 字符串 | Harmony 页身份即 pageId，等价 |

## 验证

- `d05-original-page-overview-search.mjs`：24 断言全绿。
- 全量 Desktop Replay：531/531。
- `note@ohosTest` / `note@default` clean 构建成功，无新增 ArkTS
  错误。
- 未运行模拟器/真机/Hypium。
