# Phase 1379 evidence：画布空白处长按菜单图标

## 目标

`NoteCanvasView.ClipboardPasteContextMenu`（画布空白处长按菜单，对应原版
`yqa.f`/`m18.m0` 的 `{PASTE, SELECT_ALL}`）的 MenuItem 补上图标。

## 原版证据

- `yqa.f` / `m18.m0`：空白处长按只产出 `{PASTE, SELECT_ALL}`，PASTE 受
  `hasPrimaryClip` 门控（ordinal2），SELECT_ALL 无门。
- drawable：`ui_designsystem__paste_content_manager`、`ui_designsystem__select_all`。

## 图标映射（startIcon）

| MenuItem content | startIcon | 原版 drawable |
|---|---|---|
| `paste` | `app.media.selmenu_paste` | `ui_designsystem__paste_content_manager` |
| `select_all` | `app.media.menuicon_select_all` | `ui_designsystem__select_all` |

## 新增 media 资源

- `menuicon_select_all.svg`（`ui_designsystem__select_all`，24×24，双 path 描边）。
- `selmenu_paste` 复用 Phase 1375 资产。

## 语义保持

- 仅加 `startIcon`；`content`/`onClick`/门控不变。
- `paste` 仍受剪贴板/系统图片可用性 + `photoImportBusy` 门控，
  元素剪贴板优先、系统图片兜底的两条粘贴路径不变。
- `select_all` 仍调 `selectAllPageElements()`；外层 `recentInteractionGateActive()` 不变。

## 验证

- Replay fixture `d02-original-canvas-context-menu-icons.mjs`：9/9。
- `note@default` 静态构建绿。
