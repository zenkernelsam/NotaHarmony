# Phase 1378 evidence：页缩略图长按菜单图标

## 目标

`PageOverviewPanel.buildCellMenu`（页概览网格长按某页的上下文菜单）的
9 个页操作项补上原版矢量图标，与 Phase 1377 `PageManagerBar` 页操作
菜单对齐。

## 原版证据

- `n9j.java` / `fd2.java`：页操作菜单管线，每条 `h1a`/`r68` 菜单项都携带
  一个 vector painter（add_page/cut/copy/paste/duplicate/rotate/clear/delete）。
- drawable 源：`resources/res/drawable/ui_designsystem__*.xml`
  （`add_page`、`cut`、`copy`、`paste_content_manager`、`duplicate`、
  `rotate_page`、`clear_page`、`trash`、`check_circle_fill`）。

## 图标映射（startIcon）

| MenuItem content | startIcon | 原版 drawable |
|---|---|---|
| `add_page` | `app.media.menuicon_add_page` | `ui_designsystem__add_page` |
| `cut_page` | `app.media.selmenu_cut` | `ui_designsystem__cut` |
| `copy_page` | `app.media.selmenu_copy` | `ui_designsystem__copy` |
| `paste_page` | `app.media.selmenu_paste` | `ui_designsystem__paste_content_manager` |
| `duplicate_page` | `app.media.selmenu_duplicate` | `ui_designsystem__duplicate` |
| `rotate_page` | `app.media.menuicon_rotate_page` | `ui_designsystem__rotate_page` |
| `clear_page` | `app.media.menuicon_clear_page` | `ui_designsystem__clear_page` |
| `delete_page` | `app.media.selmenu_delete` | `ui_designsystem__trash` |
| `pages_menu_select` | `app.media.menuicon_select_circle` | `ui_designsystem__check_circle_fill` |

## 新增 media 资源

- `menuicon_add_page.svg`（`ui_designsystem__add_page`，24×24）
- `menuicon_select_circle.svg`（`ui_designsystem__check_circle_fill`，24×24）

其余 7 项复用 Phase 1375（`selmenu_*`）与 Phase 1377（`menuicon_rotate_page`、
`menuicon_clear_page`）已生成的资源，保证页操作在两处菜单图标一致。

## 语义保持

- 仅加 `startIcon`，`content`/`onClick`/门控条件不变。
- `paste_page` 仍 `if (this.canPaste)`、`rotate_page` 仍
  `rotatedOriginalPageInfo(this.page) !== null` 条件渲染。
- 动作回调全部经 `onMenuAction(this.pageIndex, …)` / `onToggleSelect` 原样保留。

## 验证

- Replay fixture `d02-original-page-cell-menu-icons.mjs`：21/21。
- `note@default` 静态构建绿。
