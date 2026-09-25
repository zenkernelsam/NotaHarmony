# 原版证据：feature_note__ 族尾部 — JADX 静态审计（2026-09-25）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
（JADX 反编译 Notability 1.0.3，只读证据）

## 1. HWR 方法面板（x22 / y22 / ysh / gs8）

```text
feature_note__hwr_panel_title            Handwriting Recognition
feature_note__hwr_panel_detect_handwriting  Detect Handwriting
feature_note__hwr_panel_detect_math      Detect Math (LaTeX)
feature_note__hwr_panel_selected_method  Selected Method
feature_note__hwr_panel_close_description  Close Handwriting Recognition panel
feature_note__hwr_toggle_description     Toggle Handwriting Recognition panel
```

- `ysh.java:112-115`：面板标题 `hwr_panel_title` + 右上角关闭钮
  `hwr_panel_close_description`（`e2j.a` 图标钮）。
- `y22.java:26/39`：两个方法行 `detect_math` / `detect_handwriting`。
- `x22.java:161`：当前方法提示 `hwr_panel_selected_method`
  （`tpe.b` 文本）。
- `gs8.java:47-48`：工具栏 `hwr_toggle` 图标钮 a11y
  `hwr_toggle_description`。

后端：识别 provider 为 MyScript iink（`xsc.p()` 能力门禁，已在
ADR-0645 就 CONVERT_* 菜单项登记）。面板只是方法选择 UI，无
provider 即无功能，随菜单项一并 fail-closed。

## 2. deselect 确认/取消（v22.java）

`v22` case 9/10：deselectMode 下专用条两侧为 ✕(`deselect_cancel`) /
✓(`deselect_confirm`) 图标钮，`go5.b` contentDescription 即
对应字符串。Harmony `SelectionOverlay.buildSelectionMenu` 在
deselectMode 下收窄菜单为 Done/Cancel 两项——语义等价、形态为
菜单项而非专用条，登记形态偏差。

## 3. copied_pdf_text（q39.java）

`q39 extends ActionMode.Callback2`：PDF 文本系统选中 CAB 的回调；
`copied_pdf_text`（"Copied PDF Text"）为复制成功 toast。Harmony
PDF 页是位图背景渲染（ADR-0049），无可选文字层 → 该 toast 路径
不存在，fail-closed。

## 4. 协作/账号/旗标绑定键（引用既有登记）

- `access_denied_*`（3 键，`u49.java`）："Permission required /
  You do not have permission to access this note. / Done" —
  共享协作权限拒绝对话框 → ADR-0513/0662 账号协作边界。
- `view_only*`（3 键）、`presence_recording*`（2 键）：协作只读
  与在场录音提示 → ADR-0513。
- `version_history_*`（12 键）：`ac4.d0` 旗标门控 + 付费墙
  （ADR-0544/0662）。
- `cd_quick_tool_*`（5 键）：SPen Quick Tools a11y（Phase 709）。
- `learn_toggle_description`：ADR-0652 Learn AI 边界。
- `youtube_*`（7 键）：ADR-0651 YouTube 转录 fail-closed。
- `options_menu_inky`：Phase 708 Inky Rive 边界。
- `download_failed_*`：云端下载失败提示 → 账号同步边界
  （ADR-0662）。
- `text_conversion_failed`/`math_conversion_failed`：CONVERT_*
  菜单 fail-closed 的伴随 toast（ADR-0645）。

## 5. 结论

尾部未登记键全部归类：`hwr_panel_*`/`hwr_toggle`/`copied_pdf_text`
为本 ADR 新增登记的边界/偏差项；其余均已由早期 phase 移植或
fail-closed 覆盖。`feature_note__` 148 键审计闭合。
