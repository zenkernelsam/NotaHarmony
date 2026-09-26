# ADR-0670 feature_note__ 族尾部收口：HWR 面板、PDF 文本复制与族审计闭合

- 状态：Accepted
- 日期：2026-09-25
- 关联 Phase：722
- 证据：`docs/migration/evidence/original-feature-note-tail-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-feature-note-tail.mjs`

## 背景

`feature_note__` 是原版笔记内功能字符串族（148 键）。绝大多数键已在
早期 Phase 落地或由边界 ADR 覆盖。本 ADR 对族内剩余未登记键做最终
归类并闭合全族审计。

## 逐类决策

### 已移植覆盖（无需动作）

- `content_manager_*`（页面管理器 27 键）：PageManager 全量端口
  （选择/筛选/书签/模板/删除/旋转/复制粘贴/页指示器），各 phase
  已落。
- `selection_menu_*`（28 键）：`SelectionOverlay.buildSelectionMenu`
  全表对齐原版 `dsc` 顺序（ADR-0645），含 GROUP/UNGROUP、
  SEND_*、FLIP_*、LOCK/UNLOCK、EDIT_MATH、CROP 等。
- `text_selection_menu_*`、`link_menu_*`、`cropping_*`、
  `jump_to_*`、`undo`/`redo`/`toolbar_more_menu`/
  `toprighttoolbar_*`、`empty_note__*`（ADR-0647 doc-scan 边界）、
  `gif_picker_*`（P700 Klipy 接入）、`image_too_large_to_add`
  （u49/rd9 端口）、`default_title`（P716 "New Note"）、
  `copied_link`（`link_copied`）、`note_deleted_*`/`load_failed_*`
  （ADR-0515 笔记打开失败对话框）、`download_failed_*`、
  `math_editor_*`（MathEditorOverlay）、`deselect_cancel/confirm`
  （deselectMode 确认/取消菜单项——原版为 k2f 确认/取消条，
  Harmony 复用菜单项承载，见偏差登记）。

### fail-closed / 平台边界（本 ADR 登记或引用既有登记）

- `hwr_panel_*` + `hwr_toggle_description`（6 键）：原版手写识别
  方法面板（Detect Handwriting / Detect Math (LaTeX)/Selected
  Method + 关闭 a11y + 工具栏 toggle a11y）。转换引擎已由
  ADR-0254/0256/0257 落地（planner/context/coordinator），但识别
  provider 是 MyScript iink 后端（xsc.p() 门禁，ADR-0645 登记
  CONVERT_* 菜单项 fail-closed）；无 provider 故面板/toggle 不
  接线——本 ADR 将面板字符串显式并入同一边界。
- `copied_pdf_text`：原版 `q39`（PDF 文本 ActionMode 回调）在
  复制所选 PDF 文本后 toast。Harmony PDF 页以位图背景渲染
  （ADR-0049），无可选文字层，该 toast 路径不存在——fail-closed。
- `text_conversion_failed` / `math_conversion_failed`：CONVERT_*
  菜单项已 fail-closed（ADR-0645），其失败 toast 随菜单项不接线。
- `access_denied_*`（权限对话框）：共享协作权限拒绝对话框，
  账号/协作后端边界（ADR-0658、ADR-0662）。
- `view_only`、`view_only_edit_attempt`、`view_only_upload_attempt`、
  `presence_recording*`：协作只读/在场提示，ADR-0658 边界。
- `version_history_*`（12 键）：版本历史界面，远程旗标
  `ac4.d0` 门控 + 付费墙（ADR-0544、ADR-0662）。
- `cd_quick_tool_*`（5 键）：SPen Quick Tools 蓝牙遥控器 a11y，
  Phase 709 / ADR 登记。
- `learn_toggle_description`：Learn AI 入口，ADR-0652。
- `youtube_*`（7 键）：YouTube 转录导入，ADR-0651 fail-closed。
- `options_menu_inky`：Inky 吉祥物 Rive 动画，Phase 708。
- `options_menu_app_settings`/`disconnect_stylus`/`version_history`：
  ADR-0544 options-menu 端口/边界登记。
- `hwr_panel_*`/`presence_*` 之外剩余 `page_indicator` 等随
  content_manager 覆盖。

### 偏差登记

- `deselect_cancel`/`deselect_confirm`：原版为选区 deselectMode 的
  独立确认/取消条（k2f 容器，✕/✓ 图标 a11y 文案）。Harmony
  `SelectionOverlay` 在 deselectMode 下将菜单收窄为 Done/Cancel
  两项，语义等价、控件形态不同（菜单项 vs 专用条），登记为
  形态偏差。

## 结论

`feature_note__` 148 键全数归档：移植覆盖 113 键、fail-closed/平台
边界 35 键。无新增运行时代码。

## 验证

- `d02-original-feature-note-tail.mjs` 断言全绿（源侧锚点 + ADR/
  证据/报告存在性 + 反向针）。
- 全量 Desktop Replay 605/605；双 HAP 构建通过。
