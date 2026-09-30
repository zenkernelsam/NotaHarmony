# ADR-1314：页缩略图长按菜单挂原版矢量图标

- 状态：Accepted
- 关联：Phase 1378、ADR-1313（页操作菜单图标）、evidence `phase-1378-original-page-cell-menu-icons.md`

## 背景

页概览网格中长按某页弹出的上下文菜单（`PageOverviewPanel.buildCellMenu`）承载
9 个页操作：add_page / cut_page / copy_page / paste_page / duplicate_page /
rotate_page / clear_page / delete_page / pages_menu_select。

在 Phase 1378 之前，这些 `MenuItem` 只有 `content`（文字），没有图标。
原版页操作菜单（`n9j.java` / `fd2.java` 的页菜单管线）每一项 `h1a`/`r68`
条目都带一个 vector painter。Harmony 的纯文字菜单因此缺一层原版视觉信息。

## 决策

为 `buildCellMenu` 的每个 `MenuItem` 加 `startIcon`（ArkUI `MenuItem` 原生
前置图标的属性），映射到原版页菜单的对应 drawable；该集合与 Phase 1377 的
`PageManagerBar` 页操作菜单一致，复用其已生成的 media SVG，仅补 `add_page`
与 `pages_menu_select` 两个新资源：

| Harmony 项 | startIcon | 原版 drawable |
|---|---|---|
| add_page | `menuicon_add_page` | `ui_designsystem__add_page` |
| cut_page | `selmenu_cut` | `ui_designsystem__cut` |
| copy_page | `selmenu_copy` | `ui_designsystem__copy` |
| paste_page | `selmenu_paste` | `ui_designsystem__paste_content_manager` |
| duplicate_page | `selmenu_duplicate` | `ui_designsystem__duplicate` |
| rotate_page | `menuicon_rotate_page` | `ui_designsystem__rotate_page` |
| clear_page | `menuicon_clear_page` | `ui_designsystem__clear_page` |
| delete_page | `selmenu_delete` | `ui_designsystem__trash` |
| pages_menu_select | `menuicon_select_circle` | `ui_designsystem__check_circle_fill` |

`paste_page` 仍受 `canPaste` 门控，`rotate_page` 仍受
`rotatedOriginalPageInfo(...) !== null` 门控——图标是附加的可选属性，
不改变任何动作回调或显隐语义。

## 理由

- `fd2`/`n9j` 的页菜单条目在原版即带图标；`MenuItem.startIcon` 是 ArkUI
  为上下文菜单项提供的等价承载位，比文字-only 更贴近原版的 icon+label 行。
- 复用 Phase 1375/1377 已生成的 media SVG（cut/copy/paste/duplicate/delete/
  rotate/clear）保证同一操作在两处菜单里图标一致，避免重复资产。
- `pages_menu_select` 语义是"把该页并入选择集（进入选择态）"，原版的
  `check_circle_fill` 勾选圆即对应"标记/选中"，用作其图标最贴切。

## 兼容性

- 仅加 `startIcon`，不动 `content`、`onClick`、门控条件与菜单结构；
  a11y 仍由 `content` 文字提供，图标为纯视觉补充。
- 无新增 ArkTS 静态错误；`menuicon_add_page`、`menuicon_select_circle`
  为新增 media SVG，其余复用既有资源。
