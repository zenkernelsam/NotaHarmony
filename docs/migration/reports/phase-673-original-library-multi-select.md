# Phase 673 — 原版库内多选模式与批量笔记操作

日期：2026-09-24
前置：Phase 672（`e859cdbc`）

## 目标

把库页面升级为原版的双通道单元格语义：**长按进入多选
模式**（`pk9.o`），**⋯ 溢出按钮承载单笔记菜单**
（`d5j`）；并在多选态提供顶栏（全选/计数/Done）与底栏
批量动作（Duplicate / Favorite↔Unfavorite / Delete）。

## 原版行为（证据：pk9/tj9/xj9/d5j/hof/l05/ek9/o94/lq7/strings）

- `pk9`：`X`=模式开关、`Y`=选中集；`o(ttf)` 进入并立即
  选中长按项；`r(ttf)` 翻转成员；`p()` 退出并清空。
- `tj9` case0/6 → `pk9.o`（长按进多选）；`d5j` 单笔记
  菜单无 Select 项，由 ⋯ 图标单独触发。
- `hof` 顶栏：`set.size() != list.size()` → Select All
  否则 Deselect All；空选中集隐藏动作区。
- `l05`/`ek9` 底栏：Duplicate/Favorite/Delete，
  `ek9.b`=actionsEnabled、`ek9.e`=allSelectedAreFavorited
  驱动 Favorite↔Unfavorite 翻转；busy 时进度（`xri.a`）。
- `o94` 勾选圈；`lq7` 返回键 → `pk9.p`；Share 受
  `lc4.a(ac4.L)` 旗标门控。

## Harmony 实现

`LibraryPage.ets`：

- 状态：`@State isMultiSelecting` / `selectedNoteIds` /
  `multiSelectBusy`。
- 进入/退出：`enterMultiSelect`（守卫 + X→true + 选中
  长按项）、`toggleMultiSelectId`、`exitMultiSelect`、
  `onBackPress` 多选态消费返回。
- 单元格：`LongPressGesture` → `enterMultiSelect`；
  多选态 `onClick` → `toggleMultiSelectId`；原长按
  `bindContextMenu` 改为 ⋯ `NoteMenuButton`（`bindMenu`）
  承载 `d5j` 菜单；`SelectCircle` 勾选圈（o94）。
- 顶栏 `MultiSelectTopBar`：Select All/Deselect All +
  单复数计数 + Done。
- 底栏 `MultiSelectActionBar`：Duplicate /
  Favorite↔Unfavorite / Delete；`enabled=count>0&&!busy`；
  busy `LoadingProgress`；Delete 弹计数确认。
- 批量：`multiDuplicate`（无损 export→import 往返 +
  重载 + 剔除失效 id）、`multiSetFavorite`（目标态部分
  变基）、`multiDelete`（逐笔记入 Recently Deleted，
  删空自动退出）；FAB 多选态隐藏。
- 字符串：base+zh_CN 新增 share/deselect_all/
  notes_selected/note_selected_singular/select_note/
  note_actions/delete_notes_message/multi_*_failed。

## 登记差异

1. ⋯ 溢出按钮 `bindMenu` 承载 `d5j`（长按让位 `pk9.o`）。
2. Share 图标 fail-closed → Phase 674 多笔记分享。
3. ✓/边框圆近似 `o94` 图标。
4. 笔记 id 直用字符串（无 ttf 包装层）。

## 验证

- `d02-original-library-multi-select.mjs`：44/44。
- 全量 Desktop Replay：558/558。
- `note@ohosTest` + `note@default` 双 HAP clean 构建成功。
- 无模拟器/真机/Hypium（按约束）。

## 后续登记

- Phase 674：多笔记分享（`s6d _multi` 标签 + 多文件交付面
  + `v6d.a` isMultiNote 隐藏页范围）。
