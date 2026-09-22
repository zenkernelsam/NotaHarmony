# ADR-0518 — 原版库排序字段+方向

状态：Accepted（Phase 546）

## 背景

原版库排序为二维：`he7` 字段（NAME/CREATED_DATE/MODIFIED_DATE）×
`je7` 方向（ASC/DESC），z97 默认 MODIFIED_DATE+DESCENDING；
`pk9.s` 字段比较器产升序列表、DESC 经 `au1.E1` 反转；UI 为字段
chip + 独立方向箭头（`inh.b`），下拉内含字段行+方向行（`vc2`）。
Harmony 此前为 3 个固定方向模式（UPDATED/CREATED desc、TITLE asc），
无法表达 Modified-asc、Name-Z→A 等组合。

## 决策

1. `NoteSortMode` 保留为字段枚举（TITLE↔NAME、CREATED↔CREATED_DATE、
   UPDATED↔MODIFIED_DATE），新增独立 `sortDescending`（默认 true）。
2. `applySort` = 字段升序 + `reverse()`——逐行对应 pk9.s。
3. UI：侧栏头部字段 chip（标签=当前字段名）+ ↑/↓ 方向按钮直接
   翻转；两处菜单均为 3 字段行 + 2 字段感知方向行。
4. 持久化新增 `library_sort_dir`（缺省 DESCENDING），与
   `library_sort_mode` 并列恢复。

## 后果

旧 "TITLE" 模式语义由固定 asc 变为跟随方向（默认 desc → Z→A），
与原版一致；既有升级用户在 TITLE 下的顺序会翻转——可接受（原版
同字段同方向行为）。

## 验证

`d02-original-library-sort-direction.mjs` 30/30（含 asc+reverse
可执行模型）；`LibraryViewModel.test.ets` 排序用例扩展方向断言；
全套 441/441；`note@default` + `note@ohosTest` BUILD SUCCESSFUL。
