# Phase 722 中文报告：`feature_note__` 族尾部收口（审计闭合）

## 范围

`feature_note__` 为原版笔记内功能字符串族（148 键）——选区菜单、
页面/内容管理器、手写识别、数学编辑器、链接/裁剪/跳转、版本历史、
协作只读、YouTube 转录等。本 phase 对族内全部 148 键做逐键归类，
补齐尾部未登记项并闭合全族审计。

## 原版证据

见 `docs/migration/evidence/original-feature-note-tail-jadx-2026-09-25.md`：

- `ysh`/`y22`/`x22`/`gs8`：HWR 方法面板（标题/Detect Handwriting/
  Detect Math (LaTeX)/Selected Method/关闭与工具栏 toggle a11y）。
- `v22` case 9/10：deselectMode 专用条 ✕/✓ 图标 a11y
  （`deselect_cancel`/`deselect_confirm`）。
- `q39 extends ActionMode.Callback2`：PDF 文本选中 CAB，
  `copied_pdf_text` 复制成功 toast。
- `u49`：`access_denied_*` 共享协作权限拒绝对话框。

## 审计结论（148 键归档）

### 已移植覆盖（113 键）

- `content_manager_*` 27 键 → PageManager 全量端口。
- `selection_menu_*` 28 键 → SelectionOverlay 全表对齐 dsc 顺序
  （ADR-0645）。
- `link_menu_*`、`text_selection_menu_*`、`cropping_*`、
  `jump_to_*`、`undo`/`redo`/`toolbar_more_menu`/
  `toprighttoolbar_*`、`math_editor_*`、`copied_link`、
  `note_deleted_*`/`load_failed_*`（ADR-0515）、
  `image_too_large_to_add`（u49/rd9）、`default_title`（P716）、
  `empty_note__import_file`/`record_audio`/`capture_and_add`、
  `gif_picker_*`（P700）等。

### fail-closed / 平台边界（35 键）

- 本 phase 新登记：`hwr_panel_*` + `hwr_toggle_description`（6 键，
  识别 provider 为 MyScript iink 后端门禁——无 provider 故方法面板
  与工具栏 toggle 不接线）；`copied_pdf_text`（PDF 位图渲染无文字
  层，toast 路径不存在）；`deselect_cancel/confirm` 形态偏差登记
  （原版专用条 vs Harmony 菜单收窄）。
- 引用既有登记：`access_denied_*`/`view_only_*`/`presence_*`/
  `download_failed_*`（ADR-0513/0662 协作账号边界）、
  `version_history_*`（ADR-0544 旗标 + ADR-0662 付费墙）、
  `cd_quick_tool_*`（Phase 709 SPen）、`learn_toggle`（ADR-0652）、
  `youtube_*`（ADR-0651）、`options_menu_inky`（Phase 708）、
  `options_menu_app_settings`/`disconnect_stylus`/`version_history`
  （ADR-0544）、`empty_note__scan`（ADR-0647 ML Kit）、
  `selection_menu_convert_to_*`/`text_conversion_failed`/
  `math_conversion_failed`（ADR-0645 iink 边界）。

## 变更

无运行时代码变更——纯审计闭合 + 边界登记 phase。

## 验证

- 新增 Replay：`docs/migration/replays/d02-original-feature-note-tail.mjs`
  （30 断言全绿）。
- 全量 Desktop Replay：606/606 全绿。
- `note@default` / `note@ohosTest` 双 HAP 构建通过（clean 后复验）。

## 涉及文件

- `docs/migration/adr/ADR-0670-original-feature-note-tail.md`
- `docs/migration/evidence/original-feature-note-tail-jadx-2026-09-25.md`
- `docs/migration/replays/d02-original-feature-note-tail.mjs`
