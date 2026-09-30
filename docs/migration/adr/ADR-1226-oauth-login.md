# ADR-1226：OAuth Web 登录

## 状态

已接受（Phase 1282）。

## 决策

Apple/Microsoft Web OAuth → Harmony `Web`/`webview.
WebviewController` 拦截 callback_url 重定向；GMS 登录
→ fail-closed（华为账号或省略）。

## 理由

`AppleSignInActivity`=WebView+`auth_url`/`callback_url`
拦截；`MicrosoftSignInActivity`=深链 `h(Uri)` 回调+
`aa8` 结果 —— Web 授权流（授权页→回调 URL→code→
token）。

## 后果

Harmony 登录 = Web 组件拦截回调 —— OAuth 流语义
保真；GMS 登录替换为华为账号或省略。
