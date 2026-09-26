# Phase 771 — 原版 1.4.2 Passkey/SSO 与 API 门控 Firebase 登记

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-771-original-passkey-sso.md`
ADR：`ADR-0715-original-passkey-sso.md`
Replay：`d02-original-passkey-sso.mjs`（6/6）

## 本阶段做了什么

登记 1.4.2 新增认证面与 Firebase 初始化门控：

- Passkey：`androidx.credentials` 库 + 登录/设置两侧字符串族
  （`sign_in_with_passkey`、`add_passkey`、屏幕锁前置提示等）+
  `sso_web_client_id` 配置键。
- 异常族：MalformedPasskeyPayload/PasskeyActivityGone/
  SsoVerification/NullAuthToken。
- `ApiGatedFirebaseInitProvider`：`onCreate` 前置 `ib5.a`
  门控——Firebase/Crashlytics 初始化可被远端配置关闭。

## 分类

- Passkey/SSO：账号后端 + androidx.credentials 双绑定，
  fail-closed（ADR-0715，叠加 ADR-0659）。
- API 门控初始化：GMS 簇 fail-closed，模式登记为架构注记。

## 验收

- Replay 6/6 绿；全量套件与双 HAP 随本阶段执行。
- 三项跟踪文档已更新。
