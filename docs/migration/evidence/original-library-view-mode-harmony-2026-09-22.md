# Phase 547 — 原版库网格/列表视图切换（Harmony 证据）

日期：2026-09-22
范围：`note/src/main/ets/ui/library/LibraryPage.ets`、双语言字符串、
专项 replay。

## 原版证据链（decompiled_1.0.3）

- `ie7.java`：视图模式枚举 `GRID(0)`/`LIST(1)`。
- `z97.java`：`y97` prefs 含视图模式，缺省 `GRID`。
- `inh.d`：工具条图标按钮——点击派发相反模式
  （`ie7Var2 = current==LIST ? GRID : LIST`，`ej9(26)`）。
- `zy7` case 20：图标描绘**目标**模式——GRID 态显示
  `feature_library__list_bullet`，LIST 态显示
  `feature_library__grid_view`。
- `yj9`：按 `ie7.ordinal()` 分派渲染——GRID 用 `b5j.b` 卡片格网，
  LIST 用 `m5j.b` 紧凑行（缩略图 + 标题/日期/徽标列）。

## Harmony 落地

- `@State listView` + `library_view_mode` pref（0=GRID 默认/1=LIST），
  `initData` 恢复。
- 侧栏头部方向箭头旁新增图标按钮：GRID 态显示 `☰`（对应
  list_bullet=目标 LIST）、LIST 态显示 `⊞`（grid_view=目标 GRID），
  点击 `toggleViewMode`（pageActive 守卫 + 持久化）。
- 紧凑模式 `buildLibraryActionsMenu` 增加"列表视图/网格视图"项
  （标签为目标模式名）。
- 内容区按 `listView` 分派：`List`+`NoteListRow`（48×64 缩略图 +
  标题/日期/文件夹 chip/♥/🎙 列）vs 原 `Grid`+`NoteCard`；
  点击/长按上下文菜单/缩略图懒加载行为与卡片一致。

## 差异登记

- 图标为 ⊞/☰ 字形而非矢量 grid_view/list_bullet（登记）。
- 行卡为简化紧凑行（无原版 m5j.a 的选择复选框等多选装饰——Harmony
  库无多选模式）。
