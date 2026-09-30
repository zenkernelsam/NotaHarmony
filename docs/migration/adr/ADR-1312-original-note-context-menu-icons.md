# ADR-1312 — 库笔记卡片上下文菜单项挂原版矢量图标

- Phase：1376
- 状态：Accepted（同 ADR-1311 的着色待核验说明）
- 日期：2026-08-09
- 关联：ADR-1311（选区菜单图标）/ ADR-0513（库笔记菜单缺省登记）。

## 背景

`LibraryPage.NoteContextMenu`（`Menu`+`MenuItem`）此前是纯文本。原版
`d5j.java` 中每个 `apb.f` 菜单行都是 icon+label（`h1a`/`rh8.K`/`ue4`
painter）。本 Phase 逐项挂 `MenuItem.startIcon` → 原版矢量。

## 图标映射（d5j → media）

| 菜单项 | 原版 drawable | media |
|--------|---------------|-------|
| rename | `ui_designsystem__edit` | `edit.svg`（已有） |
| favorite/unfavorite | `__favorite_outline`/`__unfavorite_outline` | `menuicon_favorite`/`_unfavorite` |
| duplicate | `ui_designsystem__duplicate` | `selmenu_duplicate`（复用） |
| export | `ui_designsystem__export` | `menuicon_export` |
| show_in_folder | `ui_designsystem__show_in_folder` | `menuicon_showfolder` |
| move_to_folder | `sort_to_folder` 复用 `__show_in_folder` | `menuicon_showfolder` |
| copy_note_id | `ui_designsystem__note_info` | `menuicon_noteinfo` |
| delete | `ue4.z()` = `ui_designsystem__trash` | `selmenu_delete`（复用） |

新增 5 个 media SVG（favorite_outline/unfavorite_outline/export/
show_in_folder/note_info），由 `_gen_menuicons.cjs` 转换；edit、
duplicate、trash 复用已有资源。

## 差异说明

- 同 ADR-1311：`startIcon`/`icon` 按资源原样渲染，深色菜单下图标对比度
  待真机核验。
- `export_options`/`open_in_new_window`/`report_note` 三项仍为 fail-closed
  缺省（ADR-0513），本 Phase 不引入。
- `move_to_folder` 菜单带 `builder` 子菜单（`MoveNoteSubMenu`），
  保持原有展开行为；图标取原版 `sort_to_folder` 的 `show_in_folder`。

## 验证

- `d02-original-note-context-menu-icons.mjs`：17/17。
- `note@default`/`note@ohosTest` 静态构建成功。
