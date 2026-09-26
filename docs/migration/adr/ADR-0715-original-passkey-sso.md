# ADR-0715 — 原版 1.4.2 Passkey/SSO 与 API 门控 Firebase 登记

日期：2026-09-29
状态：已登记（版本差·账号/GMS 边界，维持 fail-closed；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-771-original-passkey-sso.md`
Replay：`docs/migration/replays/d02-original-passkey-sso.mjs`
上游：ADR-0708、ADR-0659（账号边界）

## 背景

1.4.2 新增 Passkey/SSO 登录面：`androidx.credentials` 库、
`feature_login__passkey_*`/`feature_settings__*passkey*` 字符串族
（含屏幕锁前置文案）、`sso_web_client_id` 配置键、四个认证异常类，
以及 `ApiGatedFirebaseInitProvider`——Firebase 初始化被 `ib5.a`
API 门控闸住。

## 决策

1. Passkey/SSO 维持**账号+GMS 双重边界 fail-closed**：认证对端是
   GingerLabs 后端（`SsoVerificationException`/`MalformedPasskeyPayload`），
   本地实现依赖 Android CredentialManager；Harmony 无对应后端，
   不伪造登录路径。
2. `ApiGatedFirebaseInitProvider` 属 GMS 簇 fail-closed；其
   "远端可关断初始化"模式仅作架构注记登记。
3. 本 ADR 与 ADR-0659 并存：0659 管 1.0.3 既有账号面，本 ADR 补登
   1.4.2 新增认证面。

## 后果

- Replay 钉住字符串族/异常族/credentials 库/API 门控四点。
- T-042 输入补齐登录簇版本差。
