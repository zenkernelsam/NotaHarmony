# Phase 843 — 登录提供方 + Zendesk 支持面闭合

证据：`feature/login/`、`ui/support/`（decompiled_1.4.2）

## 一、WebView OAuth 登录活动

`AppleSignInActivity`（105 行）：
- intent extras：`auth_url` + `callback_url`；缺 `auth_url` →
  `apple_sign_in_error` → `v70`（error 流）回传；
- WebView 配置：JS+DOM storage 开，wideViewport 开，缩放关；
- `flow_state` Bundle 于 `onSaveInstanceState` 保存/恢复；
- 方向锁：`setRequestedOrientation(6|7)` 按当前方向锁定；
- 结果经 `y70` sealed 流打包成 `Bundle` → `setResult(0|-1)`。

`MicrosoftSignInActivity`（195 行）：同构 + `has_received_redirect`
布尔态恢复；错误串 `microsoft_sign_in_error`。

## 二、Zendesk 支持 API（Retrofit `a` 接口，4 端点）

- `GET global/zendesk/v2/help_center/articles/search.json`
  （query/per_page）；
- 同端点按 `section`/`sort_by`/`created_after` 过滤；
- `POST global/zendesk/v2/requests.json`（工单创建）；
- `POST global/zendesk/v2/uploads.json`（附件上传）；
- `Content-Encoding: identity` 头；`ZendeskApiException` +
  模型 c–l。

## 三、相关字符串（feature_login__*，约 40+）

`continue_with_apple/google/microsoft`、`passkey_*`（771 已记
passkey 面）、`benefit_*`、persona_*（教育者等）、
`apple/microsoft_sign_in_error`、`google_sso_web_client_id`。

## 四、Harmony 侧

**无账户/登录/客服面**：无 OAuth WebView 活动、无 Zendesk
客户端、无 `signIn` 实现——整条账户链 fail-closed（依赖
GMS 凭据/第三方 OAuth 与 Zendesk 后端）。`PartialImportException`
属文件导入校验域（已在导入链路覆盖）。

## 五、结论

登录+支持面闭合：2 WebView OAuth 活动 + Zendesk 4 端点 +
login 字符串族全归因；Harmony 全链 fail-closed。
