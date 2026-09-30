# Phase 1383 evidence：工具栏内联插入按钮图标 + add_files 校正

## 原版证据（qc.java 插入下拉菜单，`apb.f` icon+label 项）

| 行 | label | icon（h1a/vh2.h） | 动作 |
|---|---|---|---|
| 64–72 | `add_files` | `ui_designsystem__paper_plain_outline` | objS |
| 73–81 | `add_photo` | `ui_designsystem__insert_media_fill_outline` | objS2 |
| 82–90 | `take_photo` | `ui_designsystem__camera_outline` | objS3 |
| 91–101 | `add_gif`（条件 function4≠null） | `ui_designsystem__gif` | objS4（未移植） |
| 107–117 | `insert_math`（条件 function5≠null） | `feature_note_toolbox__insert_math` | objS5 |

## 本阶段变更

### 1. add_files 图标校正

- Phase 1382 误映到 `attach_file`；按 qc.java:65 改为 `paper_plain_outline`
  （media `menuicon_paper.svg`，24×24，双 path）。
- 删除未再引用的 `menuicon_attach_file.svg`（送回收站）。

### 2. 内联插入按钮挂图标（`!compact` 分支）

- 新增 `InsertButton(label, icon, onTap)` @Builder：`Button(){ Row{ Image(icon)
  .fillColor(textPrimary) + Text(label,13pt) } }`，保留 `.height(32)`、
  `enabled(toolStateLoading+photoImportLeaseActive)` 与 lease-guard `onTap`。
- 4 个内联按钮 → `InsertButton(add_files,paper,onAddFiles)` /
  `InsertButton(insert_photo,insert_media,onInsertPhotos)` /
  `InsertButton(take_photo,camera,onTakePhoto)` /
  `InsertButton(insert_math,insert_math,onInsertMath)`。

## 验证

- Replay `d02-original-insert-button-icons.mjs`：10/10。
- 更新 `d02-original-take-photo-ingress`（Button→InsertButton 锚点 + InsertButton
  lease-guard）、`d02-toolbar-builders-shared-ingress-lease-bound`
  （InsertButton 转发回调断言）、`d02-original-compact-tool-menu-icons`
  （add_files→menuicon_paper）。
- `note@default` 静态构建绿。
