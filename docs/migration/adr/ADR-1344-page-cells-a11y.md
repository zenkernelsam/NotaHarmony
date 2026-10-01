# ADR-1344：页总览 cell 可访问性 + 书签角标交互 + 跳页清除钮移植

- 日期：2026-10-01
- 状态：Accepted（实现面）；fillRule 镂空以合成等价实现（见下）
- 关联：Phase 1408；页总览面板本体 ADR-0612、选择工具条 ADR-0615、
  页菜单 fd2 派发见 Phase 648 系列

## 背景

原版 1.4.2 页总览 cell（`cbn.j`）携带三处此前未移植的语义：

1. **书签角标是常渲染的可点按钮**——`fq9.d(function2,…)` 无条件挂于
   cell 右上，`ie` case2 按 `dr2Var.c` 双态渲染 fill/outline 图标 +
   编号 a11y（"Bookmark page %d" / "Remove bookmark from page %d"）。
   `wq2.invoke`：普通态点击 → `njg.b(pageKey)` 仓库写路径切换书签；
   选择态 → `pr2.D(oag.x2(cbc(pageId)))` 并入选中集。Harmony 此前仅
   在已标页渲染静态角标，不可点、无编号 cd。
2. **选择态 checkbox 的编号 a11y**——`f9n.b` 第三参为
   `cd_(de)select_page_numbered`，Harmony 此前挂静态 "Select"。
3. **跳页字段清除钮**——`or` case18：字段非空时尾部渲染
   `xmark_circle_fill`（evenOdd 镂空 × 灰圆）+ `cd_clear_page_number`，
   点击清空；Harmony 无此 affordance。
4. 选择工具条 icon cd（`bom`：copy/duplicate/delete "…selected pages"）
   与搜索钮激活态 cd（`content_manager_close_search`）。

## 决策

- **角标常渲染 + 可点**：`PageOverviewCell` 以 24×24 Stack 承载
  `bookmark_tall_fill/outline`（按 `page.bookmarked` 切换），挂编号
  `accessibilityText` 与 `onClick`：选择态转发既有 `onToggleSelect`，
  普通态转发新增 `onToggleBookmark` → 面板 `onPageBookmark` →
  `NotePage.dispatchPageContextAction('bookmark')` →
  `togglePageBookmarkAt`（复用 de2.m/ae2 v0 日记化 + undo 写路径，
  不新建存储通道）。ArkUI 内层 onClick 先于外层 cell onClick 命中，
  无需 stopPropagation。
- **编号 cd**：新增 `cd_select/deselect_page_numbered`、
  `cd_(un)bookmark_page_numbered`（`%d` 参数 = `pageIndex+1`，与原版
  `i12` 显示页码同源），en/zh 双资源。
- **选择工具条**：`SelectionActionChip` 增 `cd?: ResourceStr` 参数，
  copy/duplicate/delete 三 chip 显式挂 `cd_*_pages`（其余 chip 的
  可见文本即 a11y，默认回退 label）。
- **搜索钮**：`searchActive` 时 a11y 切 `cd_pages_close_search`。
- **跳页清除钮**：`JumpToPageDialog` 以 `Stack(alignContent: End)`
  包裹 TextInput，`inputText.length>0` 时渲染 28vp 按钮 = 15vp
  textSecondary 圆底 + 9vp `close_med_regular` ×（control 色）。
  因 ArkUI `Path` 无 `fillRule` 属性（SDK 6.0.1(21)），evenOdd 镂空
  以「底圆+前景色×」合成等价——字段底色固定为 control token，
  无镂空依赖的可变底层。

## 后果

- 页总览 cell 书签可点 + 编号 a11y 与原版语义一致；屏幕阅读器
  播报由 "Select"/"Bookmark" 升级为 "Select page 3" 等编号文案。
- 跳页字段出现非空即显的清除钮，a11y 为 "Clear page number"。
- fail-closed 项：`njg.b` 方法名不可静态判名（以同语义
  `togglePageBookmarkAt` 复用对齐）；`bom` 的 more 溢出钮与 `z7`
  条件门为呈现层差异（Harmony chip enabled 门已覆盖同语义）。

## 验证

- `docs/migration/replays/d02-original-page-cells-a11y.mjs`：56 checks。
- 全量基线 1260/1260；`note@default` 与 clean `note@ohosTest` 构建通过。
