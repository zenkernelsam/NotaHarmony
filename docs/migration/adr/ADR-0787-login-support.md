# ADR-0787 — 登录提供方与支持面归档

- 状态：已接受（整链 fail-closed）
- 证据：`docs/migration/evidence/phase-843-login-support.md`
- 回放：`docs/migration/replays/d02-login-support.mjs`（15/15）

## 决定

1. 登录面归档：`AppleSignInActivity`/`MicrosoftSignInActivity`
   WebView OAuth 活动（auth_url/callback_url extras、flow_state
   持久化、方向锁定、结果 sealed 流）+ login 字符串族
   （三提供方 CTA、passkey、persona 调研）登记不移植。
2. 支持面归档：Zendesk Retrofit 4 端点（文章搜索×2、工单、
   附件上传）+ `ZendeskApiException` 登记不移植。
3. **整条账户+客服链 fail-closed**：依赖第三方 OAuth/GMS 凭据
   与 Zendesk 后端；Harmony 无等价物且不实现账户系统。

## 后果

`feature/login` 与 `ui/support` 两包闭合；账户/客服域完成
登记，与 842（计费）构成完整的 fail-closed 外部服务面。
