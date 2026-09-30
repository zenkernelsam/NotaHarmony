# Phase 1282 报告 — Apple/Microsoft OAuth 登录

## 完成内容

- `AppleSignInActivity`=WebView Apple OAuth（`auth_url`
  打开+`v60` WebViewClient 拦截 `callback_url`→`a70`
  结果）；`MicrosoftSignInActivity`=MS OAuth 深链
  `h(Uri)` 回调（`yn7.LOGIN`+error 解析）+`aa8` 结果 —
— Web 授权登录流（授权页→回调→code→token）。

## 产出

- evidence `phase-1282-oauth-login.md`
- fixture `d02-oauth-login.mjs`（10/10）
- ADR-1226
