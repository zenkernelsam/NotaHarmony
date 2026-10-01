# Phase 1408 修复报告：页总览 cell 可访问性 + 书签角标交互 + 跳页清除钮

## 范围

原版 1.4.2 页总览（content manager）cell 的无障碍语义与书签角标
交互此前整体缺失：角标仅是已标页的静态指示，无编号描述、不可点；
选择框仅有静态 "Select" 文案；跳页字段无清除钮。本阶段按
`cbn`/`ie`/`wq2`/`bom`/`or` 证据逐项对齐。

## 原版证据（decompiled_1.4.2）

- `cbn.j`：cell 经 `fq9.d(function2,…)` 在缩略图上**无条件**渲染
  书签角标（可点按钮封装）；`ie` case2 按 `dr2Var.c` 双态出
  `bookmark_tall_fill`/`bookmark_tall_outline` 图标 + 编号 cd
  （`cd_(un)bookmark_page_numbered`，参数 `i12` = 显示页码）。
- `wq2.invoke`（角标点击）：选择态 → `pr2.D(oag.x2(cbc(pageId)))`
  该页并入选中集；普通态 → 协程 `njg.b(pageKey,…)` 仓库写路径
  切换书签。
- `cbn.j` `if(z2)`：选择态 checkbox `f9n.b` 挂
  `cd_(de)select_page_numbered`。
- `bom`：选择工具条 copy/duplicate/trash 图标钮 cd =
  "Copy/Duplicate/Delete selected pages"。
- `or` case18：跳页字段非空时尾部渲染 `xmark_circle_fill` 钮
  （`cd_clear_page_number`），点击清空输入态。
- 搜索钮激活态 cd = `content_manager_close_search` "Close search"。

## Harmony 实现

- `PageOverviewCell`（PageOverviewPanel.ets）：书签角标改为 24×24
  Stack **常渲染**，`page.bookmarked` 双态切 fill/outline 图标
  （accent/textSecondary）；挂编号 `accessibilityText`（
  `cd_bookmark/unbookmark_page_numbered`，参数 `pageIndex+1`）与
  `onClick`——选择态走既有 `onToggleSelect`（fd2 case0 等价），
  普通态走新增 `onToggleBookmark`。checkbox 挂
  `cd_select/deselect_page_numbered` 编号 cd。
- `PageOverviewPanel`：新增 `onPageBookmark` prop 并把 cell 的
  `onToggleBookmark` 透传至宿主；`SelectionActionChip` 增可选
  `cd` 参数，copy/duplicate/delete 三 chip 挂 `cd_*_pages`；
  搜索钮 `accessibilityText` 在激活态切 `cd_pages_close_search`。
- `NotePage`：`onPageBookmark` 接线 +
  `dispatchPageContextAction` 新增 `case 'bookmark'` →
  `togglePageBookmarkAt`（de2.m/ae2 v0 日记化 + undo 同一写路径，
  与批处理书签共用）。
- `PageManagerBar.JumpToPageDialog`：字段以 `Stack(End)` 包裹，
  `inputText.length>0` 时尾部渲染 28vp 清除钮——15vp
  textSecondary 圆底 + 9vp `close_med_regular` ×（control 色），
  合成 `xmark_circle_fill` 镂空外观（Path 无 fillRule，见 ADR）；
  `cd_clear_page_number`，点击 `inputText=''`；字段右 padding
  34 留位。
- 字符串：9 个 `cd_*` 键 en/zh 双资源（文案逐字对齐原版）。

## Fail-closed / 差异记录

- `xmark_circle_fill` 的 evenOdd 镂空：ArkUI Path 无 `fillRule`
  （SDK 6.0.1(21)），以「圆底+前景色×」合成等价；字段底色固定
  为 control token，无镂空依赖的可变底层。
- `njg.b` 确切方法名在多路分发中不可静态判名：以同语义
  `togglePageBookmarkAt` 复用对齐写路径。
- `bom` more 溢出钮与 `z7` 渲染门为呈现层差异：Harmony 以文字
  chip + enabled 门覆盖同语义，未改呈现形态。

## 验证

- Replay：`d02-original-page-cells-a11y.mjs` 56 项断言全绿。
- 构建：`note@default` 与 clean `note@ohosTest` 均通过。
- 全量 Desktop Replay 基线：1260/1260。
