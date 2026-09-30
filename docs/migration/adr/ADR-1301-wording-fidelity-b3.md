# ADR-1301 — UI 措辞保真修正（第三批）：跳转/工具箱/对话框/设置标签

## 状态

Accepted（已落地）。

## 背景

Phase 1358/1359 修正了控件描述、空标题回退与部分大小写差异。继续对 `string.json`
与原版 `strings.xml` 做同名/末段差分后，发现一批确证的用户可见措辞差异集中在
跳转对话框、工具箱菜单与通用对话框按钮。

## 决策

修正 13 处英文键值与 4 处中文同步值，逐一以**完整原版键名 + Harmony 调用点语境**
双重确认属于同一功能语境后方才改动：

- 跳转对话框（`PageManagerBar`）：`jump_to_title`→`Jump to`、`jump_to_page_label`→`Page`。
- 工具箱（`EditorToolbar`/`ToolboxSettingsDialog`）：`add_files`→`Add Files`、
  `insert_math`→`Insert Math`、`take_photo`→`Take Photo`、`reset_to_default`→`Reset to default`。
- 库/设置（`LibraryPage`/`PageSettingsPanel`/`TextBlockOverlay`）：`new_folder`→`Create new folder`、
  `template_settings`→`Template settings`、`font_family`→`Font family`。
- 通用对话框：`confirm`→`Confirm`、`dismiss`→`Dismiss`、`loading`→`Loading…`（U+2026）。
- 录音 chip：`record_audio`→`Record`。

中文（无原版基线）按新英文语义同步：`dismiss`→取消、`add_files`→添加文件、
`insert_math`→插入公式、`loading`→加载中…。

## 刻意不改

- 末段碰撞键：`restore_failed`（备份告警标题 vs 原版订阅恢复）、`app_name`（产品名）、
  `title`/`cancel`/`confirm`/`dismiss` 的异前缀同末段匹配。
- 转义等价（`\'`/`\"`/`\\`）与位参等价（`%s` 顺序传参≈`%1$s`）。
- 已正确的 `select_all`/`deselect_all`（`feature_library__*`/`ui_pageselection__*` 本就 Title Case）。
- `cd_delete_recording` — 语义等价（Delete Recording N），仅格式适配。

## 依据

- 证据：`docs/migration/evidence/phase-1360-wording-fidelity-b3.md`
- 报告：`docs/migration/reports/phase-1360-wording-fidelity-b3.md`
- Replay：`docs/migration/replays/d02-wording-fidelity-b3.mjs`（10/10）

## 后果

30 处累计文案对齐原版；构建通过，无新增 ArkTS 错误。
