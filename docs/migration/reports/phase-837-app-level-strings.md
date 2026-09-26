# Phase 837 — `app__*` 顶层字符串族审计

## 范围

`strings.xml` 中 40 条 `app__` 前缀（应用级非 feature 面）
逐项归因 + Harmony 反向核对。

## 原版发现

- 已归因族：kbd_shortcut×7、update×8、missing_native×2、
  shortcut×5、open_pdf×3、杂项×2；
- **新缺口族**：
  - `app_rating_*`×5——应用内评分提示（满意→商店评分 /
    不满→邮件反馈的情感分叉）；
  - `note_limit_share_*`×2——分享数量上限闸；
  - `force_logout_*`×2——后端吊销强制登出；
  - `account_deletion_notice_*`/`login_required_for_photo`/
    `error_could_not_open_new_window` 账号/平台依赖面。

## Harmony 侧

反向核对确认三无：无应用内评分（AppsGallery 走外部）、
无分享上限闸、无强制登出实现；PDF 错误已映射
（gr9.TooLarge/PdfPasswordDialog）。三个缺口均为
fail-closed 级平台/后端依赖，非移植遗漏。

## 验证

- 新 Replay `d02-app-level-strings.mjs`：**19/19**（40 条
  全枚举、各族计数、Harmony 反向核对 4 断言）。
- ADR-0781。**app 级字符串面闭合。**
