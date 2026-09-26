# Phase 780 证据：原版 1.4.2 设置面增量（打字默认/点按即输入/TTS）

日期：2026-09-29
性质：证据登记（无 Harmony 源码变更）
证据源：`decompiled_1.4.2` strings.xml `feature_settings__*` 差集
（+60/−14）、`defpackage/{rcj,dpb,gg2,j8b,o8b}.java`。
Replay：`docs/migration/replays/d02-original-settings-delta.mjs`
ADR：`ADR-0724-original-settings-delta.md`

## 1. 新增键族（+60，分组）

**打字默认族（纯本地候选）**：
- `default_font` / `default_font_size` / `default_font_style` /
  `line_spacing` / `grid_spacing` / `font` / `size` / `style` /
  `color` / `example` / `none` / `search`
- `check_spelling` + `_description`（拼写检查开关）
- `tap_anywhere` + `_description`（页面任意位置点按即输入）
- `two_finger_tap` + `_description`（双指点按手势）

**笔记标题模板族**：`default_note_title` + `prefix`/`suffix` +
`include_date`/`include_time`（自动命名模板：前后缀+日期时间）。

**朗读族**：`text_to_speech_speed` + `slower`/`faster` —
`rcj` 渲染速度滑杆（学习辅助）。

**账号/订阅/营销**：`add_passkey` + `passkey_*`（Phase 771
已登记）、`calendars`/`connect_calendar_*`（Phase 765 已登记）、
`newsletter_*`（订阅邮件营销，后端）、`restore_subscribed_elsewhere`。

**社媒页脚**：`cd_instagram`/`cd_linkedin`/`cd_threads`/
`cd_tiktok`/`cd_youtube`——设置/关于页外链描述串。

**a11y 通用**：`cd_select_note_titled`/`cd_deselect_note_titled`/
`increase_size`/`decrease_size`。

## 2. 移除键族（−14，重构非功能消失）

`logout_*`（9 键：标题/已同步/未同步/失败/倒计时）+
`sign_out`/`stay_signed_in`/`sign_out_countdown` +
`dark_theme`/`match_system_appearance`——账号登出段与主题
键在 1.4.2 重构（移入个人资料页/改键名），非功能删除。

## 3. 代码佐证

- `rcj`：`text_to_speech_speed` 标签 + 滑杆（slower/faster
  端点）——Compose 设置行。
- `dpb`/`gg2`/`j8b`/`o8b`：tap_anywhere/default_font 键的
  设置项宿主（Compose 面板簇）。

## 4. Harmony 现状

- 无 default-font/line-spacing/tap-anywhere/TTS 设置面
  （grep 命中均为无关页面 fontSize 字面量）。
- 笔记标题模板、拼写检查、双指手势均无对应。

## 5. 分类结论

- 打字默认 + 标题模板 + tap-anywhere + two-finger-tap：
  **版本差·本地候选**（纯偏好存储+编辑器行为）。
- TTS 速度：依赖系统 TTS——HarmonyOS 侧需等价物评审。
- passkey/calendar/newsletter/restore：已登记或后端边界。
- logout/theme 移除：原版重构，非差异功能。
