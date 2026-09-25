# Phase 741 — 原版 cd_* 无障碍标签尾项

- 日期：2026-09-25
- 类型：a11y 缺口修复 + 家族收口登记
- ADR：ADR-0689
- 证据：`docs/migration/evidence/original-cd-a11y-tail-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-cd-a11y-tail.mjs`

## 背景

全量审计原版 17 个 `cd_*`/`contentDescription` 字符串消费点，
按"已移植 / 等价覆盖 / 边界 / 真实缺口"四分。

## 修复

`cd_delete_recording`（"Delete %1$s"）——原版删除钮 a11y 插值
`record_recording_user_facing_name`（`m8.java:124`/`n05.java:430,364`）。
Harmony 原为静态 `delete_recording` → 新增 `cd_delete_recording`
（"Delete Recording %d"/"删除录音 %d"），`RecordingPanel` 删除钮
`accessibilityText` 插值 `index + 1`（与行标题同一命名源）。

## 等价覆盖（登记，无代码）

- `cd_open_note_action`：原版 click-label "Open note"；Harmony 卡片
  合并公告 "Open note <题>"。
- `cd_confirm`/`cd_folder_name`：NameDialog Confirm 钮 +
  `enter_folder_name` placeholder 承担。
- `cd_audio_player_settings`：速度行 + SpeedButton 等效。

## 边界（不移植）

- `cd_quick_tool_*`×5：SPen Quick Tools（ADR-0671）。
- paywall `cd_checkmark`/`cd_close`/`cd_dismiss_restore_notice`×2
  （ADR-0662）；转写 `cd_menu`。

## 验证

- 聚焦 Replay `d02-original-cd-a11y-tail`：25 断言全绿。
- 全量 Desktop Replay：9026/9026 全绿。
- ArkTS 构建 + clean + `note@ohosTest` + `note@default` 双 HAP
  成功（仅存量告警）。

## 遗留

- 模拟器/真机/Hypium 未执行（按规则）；a11y 朗读输出需真机
  验收（已登记 R-45）。
