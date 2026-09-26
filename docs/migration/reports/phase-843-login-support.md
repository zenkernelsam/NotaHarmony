# Phase 843 — 登录提供方 + Zendesk 支持面

## 范围

`feature/login/`（Apple/Microsoft WebView OAuth）+
`ui/support/`（Zendesk 工单 API）。

## 原版发现

### WebView OAuth 活动×2

- `AppleSignInActivity`：auth_url/callback_url extras、
  JS+DOM storage、flow_state 保存恢复、方向锁定、
  `apple_sign_in_error` 兜底回传 sealed `y70` 流；
- `MicrosoftSignInActivity`：同构 + `has_received_redirect`
  布尔态恢复、`microsoft_sign_in_error`。

### Zendesk 4 端点（Retrofit）

- `articles/search.json`（query/section+sort_by+created_after
  两种调用）；
- `requests.json`（POST 工单）；
- `uploads.json`（POST 附件，`Content-Encoding: identity`）；
- `ZendeskApiException` + 模型 c–l。

### 字符串

`feature_login__*`≈40：三提供方 CTA、passkey_*、benefit_*、
persona_*（教育者画像）、sso web client id。

## Harmony 侧

无账户/登录/客服面——OAuth WebView、Zendesk、signIn 均缺位，
整链 fail-closed（GMS 凭据/第三方 OAuth/Zendesk 后端均
不可移植）。

## 验证

- Replay `d02-login-support.mjs`：**15/15**。
- ADR-0787。**登录+支持面闭合。**
