# Phase 1382 evidence：紧凑工具/插入菜单图标

## 目标

`EditorToolbar.buildCompactToolMenu`（紧凑模式工具+插入溢出菜单，原版
`x5f`/`fie` 工具槽与插入按钮）的 8 个 MenuElement 补上图标。

## 原版证据

- `x5f.java`：工具槽用 `cq.h(m4f…)` 渲染分层工具 glyph（pen/pencil/
  highlighter/eraser），`rz1.c` 渲染 text/select。
- `fie.java:19`：`ui_text__add_text` = "Add Text" 插入项。
- drawable：`eraser_whole`/`eraser_partial`（单 path）、`selectrectangle_*`、
  `text_*`、`paper_plain_outline`、`insert_media_fill_outline`、`camera_outline`、
  `feature_note_toolbox__insert_math`。

## 图标映射（MenuElement.icon）

| MenuElement value | icon | 原版 drawable |
|---|---|---|
| `whole_eraser` | `menuicon_eraser_whole` | `eraser_whole` |
| `partial_eraser` | `menuicon_eraser_partial` | `eraser_partial` |
| `selection` | `menuicon_selectrect` | `selectrectangle_outline` |
| `add_text` | `menuicon_text` | `text_outline` |
| `add_files` | `menuicon_paper` | `paper_plain_outline` |
| `insert_photo` | `menuicon_insert_media` | `insert_media_fill_outline` |
| `take_photo` | `menuicon_camera` | `camera_outline` |
| `insert_math` | `menuicon_insert_math` | `insert_math` |

## 新增 media 资源

8 个 `menuicon_*.svg`（各自原生 viewport：eraser_whole 24×26、
eraser_partial 24×25、insert_media/camera/insert_math 多 path，其余 24×24）。

## 验证

- Replay fixture `d02-original-compact-tool-menu-icons.mjs`：18/18。
- `note@default` 静态构建绿。
