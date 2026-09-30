# ADR-1318：紧凑工具/插入菜单挂原版矢量图标

- 状态：Accepted
- 关联：Phase 1382、ADR-1311…1317（菜单图标化）、evidence `phase-1382-original-compact-tool-menu-icons.md`

## 背景

`EditorToolbar.buildCompactToolMenu`（紧凑/窄屏模式下的工具+插入溢出菜单，
对应原版 `x5f`/`fie` 工具槽与插入按钮）有 8 个 `MenuElement`：
whole_eraser、partial_eraser、selection、add_text、add_files、insert_photo、
take_photo、insert_math。此前全是纯文字。

## 决策

为 8 项各加 `MenuElement.icon`，映射到原版 drawable：

| Harmony 项 | icon | 原版 drawable |
|---|---|---|
| whole_eraser | `menuicon_eraser_whole` | `ui_designsystem__eraser_whole` |
| partial_eraser | `menuicon_eraser_partial` | `ui_designsystem__eraser_partial` |
| selection | `menuicon_selectrect` | `ui_designsystem__selectrectangle_outline` |
| add_text | `menuicon_text` | `ui_designsystem__text_outline` |
| add_files | `menuicon_attach_file` | `ui_designsystem__attach_file` |
| insert_photo | `menuicon_insert_media` | `ui_designsystem__insert_media_fill_outline` |
| take_photo | `menuicon_camera` | `ui_designsystem__camera_outline` |
| insert_math | `menuicon_insert_math` | `feature_note_toolbox__insert_math` |

`eraser_whole`/`eraser_partial` 在原版即单 path 图标（非 `m4f` 合成），
直接作菜单图标；`selectrectangle`/`text` 取其 `outline` 层作扁平剪影
（菜单图标不含笔刷色分层），与工具栏 `ToolGlyph` 的同名工具一致。

## 兼容性

- 仅加 `icon`，`value`/`action`/`photoImportLeaseActive` 门控不变；
  a11y 仍由 `value` 文字提供。
- 8 个新增 media SVG。
