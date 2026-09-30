# Phase 1360 — UI 措辞保真修正（第三批）

## 方法

对 Harmony `base/element/string.json` 与原版 `decompiled_1.0.3/resources/res/values/strings.xml`
做"同名键 / 末段匹配"差分，逐一核对每个候选键的**完整原版键名**与 **Harmony 调用点语境**，
仅修正语义/措辞确有差异且属于同一功能语境的键。

## 原版证据（strings.xml）

| 原版键 | 原版值 |
|--------|--------|
| `feature_note__jump_to_title` | `Jump to` |
| `feature_note__jump_to_page_label` | `Page` |
| `feature_note_toolbox__add_files` | `Add Files` |
| `feature_note_toolbox__insert_math` | `Insert Math` |
| `feature_note_toolbox__take_photo` | `Take Photo` |
| `feature_note_toolbox__reset_to_default` | `Reset to default` |
| `ui_folder__new_folder` | `Create new folder` |
| `ui_templates__template_settings` | `Template settings` |
| `ui_text__font_family` | `Font family` |
| `ui_designsystem__confirm` | `Confirm` |
| `ui_permissions__dismiss` / `ui_fileimport__dismiss` | `Dismiss` |
| `ui_fileimport__loading` | `Loading…`（省略号 U+2026） |
| `feature_note__empty_note__record_audio` | `Record` |

## 调用点核对

- `jump_to_title`/`jump_to_page_label` — `ui/editor/PageManagerBar.ets`（跳转页码对话框标题/输入框占位），即 `feature_note__jump_to_*` 语境。
- `add_files`/`insert_math`/`take_photo` — `ui/editor/EditorToolbar.ets`（工具箱按钮+菜单项），即 `feature_note_toolbox__*` 语境。
- `reset_to_default` — `ui/editor/ToolboxSettingsDialog.ets`（工具箱设置），即 `feature_note_toolbox__reset_to_default`。
- `new_folder` — `ui/library/LibraryPage.ets` 的 `folderDialogTitle`+按钮，即 `ui_folder__new_folder`。
- `template_settings` — `ui/components/PageSettingsPanel.ets`，即 `ui_templates__template_settings`。
- `font_family` — `ui/components/TextBlockOverlay.ets`，即 `ui_text__font_family`。
- `confirm` — `LibraryPage.ets:4715` 与 `BackupPage.ets:515` 均为确认对话框按钮，即 `ui_designsystem__confirm`。
- `dismiss` — `NotePage.ets:1220` 权限对话框，注释明确标注 `ui_permissions` 顺序 `"Go to Settings"+"Dismiss"`。
- `loading` — `LibraryPage`/`FolderNotesEditPage`/`NoteThumbnailEditPage` 加载指示，对齐 `ui_fileimport__loading` 省略号。
- `record_audio` — `LibraryPage.ets:2553` 创建+录音 chip，同名键 `record_audio` 对齐 "Record"。

## 修正

### base/element/string.json（13 处）

`confirm` OK→Confirm；`dismiss` OK→Dismiss；`loading` Loading...→Loading…；
`template_settings` Template Settings→Template settings；`reset_to_default` Reset to Default→Reset to default；
`new_folder` New Folder→Create new folder；`jump_to_title` Jump to page→Jump to；
`jump_to_page_label` Page number→Page；`add_files` Files→Add Files；
`take_photo` Take a photo→Take Photo；`insert_math` Math (LaTeX)→Insert Math；
`font_family` Font→Font family；`record_audio` Record audio→Record。

### zh_CN/element/string.json（4 处同步）

`dismiss` 好→取消；`loading` 加载中...→加载中…；`add_files` 文件→添加文件；`insert_math` 公式 (LaTeX)→插入公式。

## 刻意保留（核对后判定非差异）

- `select_all`/`deselect_all`（库语境）= `feature_library__*` 均为 Title Case，Harmony 已对。
- `recording_subtitle` `%s %s, %s` — 调用点按位传三参，与 `%1$s %2$s, %3$s` 渲染等价。
- `cd_delete_recording` "Delete Recording %d" — 语义等价（传 index+1），格式适配。
- `restore_failed` "Restore Failed" — BackupPage 用作备份恢复告警标题，与原版
  `feature_settings__restore_failed`（订阅恢复，不同功能）不同语境。
- `app_name` "Nota" — 产品名刻意保留。
- 转义差异（`\'` `\"` `\\`）渲染相同，不计。

## 验证

`d02-wording-fidelity-b3.mjs`：10/10 通过；两 JSON 均有效。
