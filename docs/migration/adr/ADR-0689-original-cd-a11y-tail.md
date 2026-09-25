# ADR-0689：原版 cd_* 无障碍标签尾项对齐

- 状态：已接受
- 日期：2026-09-25
- 关联：`docs/migration/evidence/original-cd-a11y-tail-jadx-2026-09-25.md`、
  `docs/migration/replays/d02-original-cd-a11y-tail.mjs`、
  `docs/migration/reports/phase-741-original-cd-a11y-tail.md`

## 背景

全量审计原版 `cd_*` 无障碍字符串（17 键）。绝大多数已由前序
Phase 移植或落在既有边界；余一个真实缺口：录音行删除钮的
a11y 文案在原版为 `cd_delete_recording`（"Delete %1$s"），插值
录音的用户可见名（`record_recording_user_facing_name`），Harmony
原为静态 "Delete recording"（证据：`m8.java:124`/`n05.java:430,364`）。

## 决策

1. 新增 `cd_delete_recording` = `"Delete Recording %d"` /
   zh `"删除录音 %d"`，`RecordingPanel` 删除钮 `accessibilityText`
   由 `delete_recording` 改 `$r('app.string.cd_delete_recording',
   index + 1)` —— 与行标题 `recording_user_facing_name` 同一命名源，
   朗读输出与原版逐字一致（"Delete Recording 2"）。
2. 等价覆盖登记（无代码改动）：
   - `cd_open_note_action`（click-label）— Harmony 卡片合并公告
     "Open note <题>"，点击语义隐含。
   - `cd_confirm`（Save folder 对勾钮）/`cd_folder_name` —
     `NameDialog` Confirm 钮 + `enter_folder_name` placeholder
     承担公告。
   - `cd_audio_player_settings` — 速度行 + SpeedButton 等效。
3. 边界登记：`cd_quick_tool_*`（SPen，ADR-0671）、
   paywall `cd_checkmark/close/dismiss`（ADR-0662）、
   `cd_menu`（转写）不移植。

## 影响

- `RecordingPanel.ets`：删除钮 a11y 插值录音名。
- `string.json` base/zh_CN：新增 `cd_delete_recording`。
- 可见差异：TalkBack/读屏下删除钮朗读 "Delete Recording N"/
  "删除录音 N"，与原版一致。
