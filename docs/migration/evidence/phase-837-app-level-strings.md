# Phase 837 — `app__*` 顶层字符串族审计

证据：`decompiled_1.4.2/resources/res/values/strings.xml`（40 条
`app__` 前缀）+ Harmony `note/src/main/ets/` 反向核对

## 一、族清单与归因

| 族 | 条目 | 归因相位 |
|----|------|---------|
| `kbd_shortcut_*` | 7 | 827 键盘帮助面 |
| `update_*`（required/ready/action_*/launch_failed） | 8 | 832 更新流 |
| `missing_native_library_*` | 2 | 800/837 native 兜底 |
| `shortcut_*`（new_note/new_photo/recent_note_long/unfiled/untitled_note） | 5 | 827 快捷项标签 |
| `open_pdf_*`（failed/password_protected/too_large） | 3 | 已映射 Harmony（NoteImporter gr9.TooLarge、PdfPasswordDialog） |
| `ok` / `error_could_not_open_new_window` | 2 | 杂项 |

## 二、Harmony 缺失族（登记）

| 族 | 原版语义 | Harmony 状态 |
|----|---------|-------------|
| `app_rating_*`（prompt_title/message/love_it/needs_work + feedback_email_subject） | 应用内评分提示：情感分叉（满意→商店评分；不满→邮件反馈） | **无**——Harmony 无应用内评分 API，AppsGallery 评价走外部流程 |
| `note_limit_share_*`（title/message） | 分享笔记数上限闸（配额/订阅门禁） | **无**——Harmony 无分享数量限制实现 |
| `force_logout_*`（title/message） | 后端吊销的强制登出提示 | **无**——Harmony 账号面独立 |
| `account_deletion_notice_*`（title/message） | 账号删除须知对话框 | 核对中（账号面独立） |
| `login_required_for_photo` | 拍照登录门控提示 | Harmony 走 picker 无需登录 |
| `app__app_rating_love_it/needs_work` 分叉 | 情感双分支 | 同上评分族 |

## 三、结论

`app__*` 40 条顶层字符串全归因：已映射/已登记族占大半；
**新登记缺口**：应用内评分流（API 不存）、分享数量闸
（功能未实现）、强制登出（账号面独立）。均为 fail-closed
而非移植遗漏——均为后端/平台依赖或产品面差异。
