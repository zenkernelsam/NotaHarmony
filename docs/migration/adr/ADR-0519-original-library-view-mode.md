# ADR-0519 — 原版库网格/列表视图切换

状态：Accepted（Phase 547）

## 背景

原版库有 `ie7` 视图模式（GRID/LIST，`z97` 持久化默认 GRID），
工具条图标按钮切换且图标描绘目标模式（`inh.d`/`zy7` case 20）；
`yj9` 按模式分派 `b5j.b` 网格卡片 / `m5j.b` 列表行。Harmony 此前
仅网格。

## 决策

1. `@State listView` + `library_view_mode` pref 持久化，默认 GRID。
2. 头部图标按钮显示目标模式字形（GRID 态 `☰`、LIST 态 `⊞`），
   紧凑菜单增加对应切换项。
3. LIST 渲染 `NoteListRow`（小缩略图 + 标题/日期/chip/徽标列），
   交互与 `NoteCard` 一致（点击打开、长按上下文菜单、可见区缩略图
   懒加载）。

## 验证

`d02-original-library-view-mode.mjs` 13/13；全套 442/442；
`note@default` + `note@ohosTest` BUILD SUCCESSFUL。
