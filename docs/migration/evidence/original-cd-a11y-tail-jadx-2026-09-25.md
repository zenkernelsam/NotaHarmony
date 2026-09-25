# 原版 cd_* 无障碍标签尾项 JADX 证据（2026-09-25）

Phase 741。全量 `cd_*` 无障碍字符串消费点审计
（`decompiled_1.0.3` 直接证据）。

## 清单（17 键 → 4 类）

| 键 | 文案 | 消费点 | 分类 |
|----|------|--------|------|
| `feature_library__cd_add_note` | Add note | 库 FAB | 已移植 |
| `cd_open_note_action` | Open note | `e5j:274` `combinedClickable` onClickLabel | 等价覆盖 |
| `cd_open_note_titled`/`cd_open_note` | Open note %1$s / Open note | 卡片 contentDescription | 已移植 |
| `cd_sort` | Sort | 排序钮 | 已移植 |
| `cd_quick_tool_{color,eraser,highlighter,pen,pencil}` | Quick tool 名 | SPen Quick Tools | SPen 边界（ADR-0671） |
| `cd_audio_player_settings` | Audio player settings | `d32` 播放器 | 等价覆盖（速度行） |
| `cd_delete_recording` | **Delete %1$s** | `m8`/`n05:430` 删除钮 | **本 Phase 修复** |
| `cd_forward_10_seconds`/`cd_rewind_10_seconds` | Forward/Rewind 10 seconds | `d32:106/116` | 已移植（±10s 钮 a11y） |
| `cd_checkmark`/`cd_close`/`cd_dismiss_restore_notice` | paywall | 付费墙 | 订阅边界（ADR-0662） |
| `feature_settings__cd_dismiss_restore_notice` | Dismiss | 恢复提示 | 同上 |
| `cd_confirm` | Save folder | `u22:36` 对勾钮 | 等价覆盖（Confirm 钮文本） |
| `cd_folder_name` | Folder name | `gaj:614` 名称字段 | 等价覆盖（placeholder） |
| `feature_learn_transcription__cd_menu` | Menu | 转写菜单 | 转写边界 |

## 修复点：`cd_delete_recording`

`m8.java:124`（`n05.java:430` 消费）：
```java
go5.b(trash_drawable,
    tl7.T(R.string.feature_note_toolbox__cd_delete_recording,
          new Object[]{str}, uz4Var7), ...)
```
`str` = `record_recording_user_facing_name`（`n05:364`，
"Recording %1$s"）—— 删除钮 a11y 朗读 **"Delete Recording N"**。

Harmony `RecordingPanel.ets` 原钉 `delete_recording`（静态
"Delete recording"）→ 改 `cd_delete_recording`（"Delete Recording %d" /
zh "删除录音 %d"），插值 `index + 1`（与行标题
`recording_user_facing_name` 同一命名源）。

## 等价覆盖说明

- `cd_open_note_action`：原版 clickable 的 onClickLabel "Open note"；
  Harmony 卡片 `accessibilityText` 合并为 "Open note <题>"，
  点击语义由卡片 onClick 隐含，等效公告。
- `cd_confirm`/`cd_folder_name`：原版对勾钮/字段 a11y；
  Harmony `NameDialog` 的 Confirm 钮文本与 `enter_folder_name`
  placeholder 承担同样公告。
- `cd_audio_player_settings`：原版齿轮 a11y；Harmony 用
  `recording_playback_speed` 行标题 + SpeedButton，等效。
