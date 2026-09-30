# ADR-1310 — 子面板揭示箭头/拖拽柄/选中勾等剩余指示标记矢量化

- Phase：1374
- 状态：Accepted
- 日期：2026-08-09
- 关联：ADR-1305/1306/1307/1308/1309（矢量字形体系与此前各占位迁移）。

## 背景

Phase 1373 收敛了库卡片/页/多选的主要状态指示。本 Phase 收尾剩余零散
占位：分享子面板的前进/返回箭头（`›`/`‹`）、缩放视图拖拽柄（`≡`）、
设置与导入单的选中勾（`✓`）、导入单排序箭头（`↑`/`↓`）、调色板自定义
颜色加入格（`+`），以及两个桌面卡片（widget）上的编辑角标（`✎`）。

## 原版证据与映射

| 界面 | 占位 | 原版 drawable / 语义 | 证据 |
|------|------|----------------------|------|
| 分享子面板前进 | `›` | `ui_designsystem__chevron_right` | `ue4` |
| 分享子面板返回 | `‹` | `ui_designsystem__chevron_left` | `ue4` |
| 缩放视图拖拽柄 | `≡` | `ui_designsystem__drag_handle` | `wfg.c` |
| 设置/导入选中勾 | `✓` | `ui_designsystem__general_check_med_reg` | — |
| 导入单上移/下移 | `↑`/`↓` | `chevron_down`（上移 rot180） | `te4`（拖拽重排+仅无障碍 move_up/down） |
| 调色板加入格 | `+` | `ui_designsystem__plus` | — |
| 卡片编辑角标 | `✎` | `ui_designsystem__edit` | widget 编辑入口 |

## 决策

- 应用内（非 widget）统一走 `ToolGlyph`：`chevron_right/left`、
  `drag_handle`（新键）、`general_check_med_reg`、`plus`。
- `te4` 原版的行内重排是拖拽手势 + 仅无障碍 `move_up`/`move_down`（无可见
  箭头）。Harmony 提供显式上下按钮这一迁移适配，映射为设计系统
  `chevron_down`（上移 = `.rotate({ angle: 180 })`），与 Phase 1371
  `▲`/`▼` 的处理保持一致并在代码内注明。
- **widget 边界（fail-closed 适配）**：`noteformability` 卡片运行在
  FormExtensionAbility 受限 ArkUI，无法用基于 `Shape`/`Path` 的
  `ToolGlyph`，也不支持自定义 `@Component` 宿主。改用 `Image` +
  `resources/base/media/edit.svg`（逐字节复刻 `ui_designsystem__edit`
  pathData），经 `.fillColor()` 着色到 widget 文本/白底色。

## 替换明细

- `EditorToolbar.ets`：`›`×2 → `chevron_right`；`‹`×2 → `chevron_left`。
- `NoteZoomView.ets`：`≡` 拖拽柄 → `drag_handle`（新增 import）。
- `SettingsPage.ets`：`✓`×2 → `general_check_med_reg`。
- `ImportDetailsSheet.ets`：`↑`/`↓` → `chevron_down`(rot180)/`chevron_down`；
  `✓` → `general_check_med_reg`（新增 import）。
- `ColorPicker.ets`：`+` → `plus`（新增 import）。
- `noteformability/pages/FolderNotesCard.ets`、`NoteThumbnailCard.ets`：
  `✎` → `Image(app.media.edit)`。
- `_gen_toolglyphs.cjs`：新增 `drag_handle`（o 槽）。`ToolGlyphs.ets` 39 键。
- 新增 `note/src/main/resources/base/media/edit.svg`。

无障碍标签保留：`import_move_up`/`import_move_down`/`zoom_view_move` 等。

## 验证

- `d02-original-subpanel-indicator-glyphs.mjs`：16/16。
- `d02-original-editor-toolbar-glyphs.mjs` 计数 38→39。
- `note@default` 静态构建成功（含 `app.media.edit` 解析）；`note@ohosTest`
  clean 构建成功。
