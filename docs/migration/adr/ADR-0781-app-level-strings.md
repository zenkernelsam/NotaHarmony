# ADR-0781 — `app__*` 顶层字符串族归档

- 状态：已接受（三缺口 fail-closed 登记）
- 证据：`docs/migration/evidence/phase-837-app-level-strings.md`
- 回放：`docs/migration/replays/d02-app-level-strings.mjs`（19/19）

## 决定

1. **应用内评分族 fail-closed**：`app_rating_*`（情感分叉+
   邮件反馈主题）无 Harmony 应用内评分 API——不实现。
2. **分享数量闸 fail-closed**：`note_limit_share_*` 原版为
   配额/订阅门禁；Harmony 无对应限制实现——不实现。
3. **强制登出族 fail-closed**：`force_logout_*` 后端吊销
   驱动的登出提示；Harmony 账号面独立——不实现。
4. `account_deletion_notice_*`/`login_required_for_photo`/
   `error_could_not_open_new_window` 等平台/账号依赖面归档。

## 后果

`app__*` 40 条顶层字符串全部归因；strings.xml 逐前缀审计
在 app 级闭合（feature_*/ui_* 族此前相位分别覆盖）。
