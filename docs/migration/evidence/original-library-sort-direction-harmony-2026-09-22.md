# Phase 546 — 原版库排序字段+方向（Harmony 证据）

日期：2026-09-22
范围：`note/src/main/ets/ui/library/LibraryViewModel.ets`、
`LibraryPage.ets`、`note/src/test/LibraryViewModel.test.ets`、
双语言字符串、专项 replay。

## 原版证据链（decompiled_1.0.3）

- `he7.java`：字段枚举 `NAME(0)/CREATED_DATE(1)/MODIFIED_DATE(2)`。
- `je7.java`：方向枚举 `ASCENDING(0)/DESCENDING(1)`。
- `z97.java`（`y97` prefs 反序列化）：`sortField` 默认
  `MODIFIED_DATE`，`sortDirection` 默认 `DESCENDING`（另有
  `ie7` GRID/LIST 视图模式——登记不移植）。
- `pk9.s(list, he7, je7, false)`：NAME→`bg1(ua5(collator))`，
  CREATED→`fh7(10)` asc，MODIFIED→`fh7(11)` asc；
  `je7==DESCENDING` 时 `au1.E1` 整体反转。`mk9` 中
  RECENT 区段绕过该排序（lastOpened desc top10，Phase 537 已落地）。
- `inh.b`：字段 chip（显示当前字段名，点击展开下拉）+ 独立方向
  箭头按钮（`SortDirectionArrow`，desc 旋转 180°，点击直接派发
  相反方向 `ej9(28)`）。
- `vc2` case 3（下拉内容）：3 个字段行（当前字段尾随
  `general_check_med_reg` ✓）+ 分隔线 + 2 个方向行——方向标签随
  字段变化：NAME→"A to Z"/"Z to A"，日期字段→
  "Oldest to Newest"/"Newest to Oldest"，当前方向尾随 ✓。

## Harmony 落地

`LibraryViewModel`：

- 新增 `sortDescending: boolean = true`（z97 DESCENDING 默认）。
- `applySort` 改为 pk9.s 语义：字段比较器先产出**升序**列表
  （UPDATED→updatedAt asc、CREATED→createdAt asc、TITLE→
  localeCompare asc），`sortDescending` 时 `reverse()`。RECENT
  旁路不变。
- 新增 `setSortDescending(desc)`；字段 `setSortMode` 与方向相互
  独立（原版同）。

`LibraryPage`：

- 新 pref 键 `library_sort_dir`（1/0，缺省 1=DESC）；保存/恢复与
  `library_sort_mode` 并列，统一走 `persistSortPreferences`。
- 侧栏头部：`Button(sortFieldLabel())`（chip 显示当前字段名，
  菜单 = 3 字段 + 2 方向行）+ 方向箭头按钮（desc↓/asc↑ 字形，
  点击 `toggleSortDirection` 直接翻转——对应原版旋转箭头）。
- 紧凑模式 `buildLibraryActionsMenu` 复用同一 `buildSortMenuItems`。
- 方向标签字段感知：TITLE→A to Z/Z to A；日期→Oldest/Newest。
- 新增 7 条字符串（双语言）。

## 差异登记

- Harmony `bindMenu` 无勾选项/分隔线——✓ 与分隔线省略（登记）。
- 箭头为 ↑/↓ 字形切换而非单图标旋转 180°（登记）。
- NAME 排序用 `localeCompare`；原版 `bg1`+`qi` 为 RuleBasedCollator
  自然排序——近似等价（登记）。
- ~~`ie7` GRID/LIST 视图切换未移植（登记）~~——已被 Phase 547
  取代（`e245cb86`：`listView` 状态 + `PREF_VIEW_MODE_KEY`
  持久化，☰/⊞ 切换钮）。
