# ADR-1319：工具栏内联插入按钮挂原版图标 + add_files 映射校正

- 状态：Accepted
- 关联：Phase 1383、ADR-1318（紧凑插入菜单图标）、evidence `phase-1383-original-insert-button-icons.md`

## 背景

原版插入动作在 `qc.java` 是一个 `apb.f` **下拉菜单**，每项都是 icon+label：
- `add_files` → `ui_designsystem__paper_plain_outline`
- `add_photo` → `ui_designsystem__insert_media_fill_outline`
- `take_photo` → `ui_designsystem__camera_outline`
- `add_gif` → `ui_designsystem__gif`（条件项，Harmony 未移植 fail-closed）
- `insert_math` → `feature_note_toolbox__insert_math`

Harmony 在宽屏（`!compact`）把这 4 项渲染为**内联文字按钮**（无图标），
紧凑模式收成 `buildCompactToolMenu` 下拉。两处此前均未完全复刻原版图标。

## 决策

### 1. 校正 add_files 图标

Phase 1382 误把 `add_files` 映射到 `attach_file`；按 `qc.java:65` 校正为
`paper_plain_outline`（新 media `menuicon_paper`）。删除未再引用的
`menuicon_attach_file.svg`。

### 2. 内联插入按钮挂图标

新增 `InsertButton` `@Builder`——`Button() { Row() { Image(icon).Text(label) } }`，
保持原 `.height(32)`/`enabled(toolStateLoading + photoImportLeaseActive)`/
lease-guard 回调结构。4 个内联按钮改为 icon+label，与原版 `apb.f` 项一致：

| label | icon |
|---|---|
| add_files | `menuicon_paper` |
| insert_photo | `menuicon_insert_media` |
| take_photo | `menuicon_camera` |
| insert_math | `menuicon_insert_math` |

紧凑菜单（`buildCompactToolMenu`）沿用同一套 icon 资产。

## 兼容性

- 图标用 `Image.fillColor(textPrimary)` 跟随主题文字色；label 保持 13pt。
- `enabled` 与 `photoImportLeaseActive` 门控收敛进 `InsertButton`，语义不变。
- `insert_math` 复用 Phase 1382 资产；新增 `menuicon_paper.svg`。
- `add_gif` 仍未移植（原版条件项，Harmony 无 GIF 插入入口）。
