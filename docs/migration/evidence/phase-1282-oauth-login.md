# Phase 1282 证据 — Apple/Microsoft OAuth 登录

来源：`feature/login/{apple/AppleSignInActivity,
microsoft/MicrosoftSignInActivity}.java`。

## `AppleSignInActivity extends r12` = Apple Web 登录

```java
p6a I = fsi.T(Boolean.TRUE)          // 加载态
a70 J;                               // 结果回调
WebView K;
onCreate {
    auth_url extra → WebView         // appleid.apple.com
    callback_url extra → v60 WebViewClient 拦截重定向
    → 回传 a70 结果
}
```

→ Apple Sign-In = WebView 打开 Apple OAuth 页 +
WebViewClient 拦截 `callback_url` 重定向拿 code。

## `MicrosoftSignInActivity extends r12` = MS OAuth

```java
aa8 I;                 // 结果
boolean J, K; tqd L;   // 状态+协程
h(Uri uri)             // 深链回调：解析 yn7.LOGIN +
                       //  "Microsoft OAuth error: "+error
onCreate { lv2.Z(bundle,"result",aa8.class) }
```

→ Microsoft OAuth = 浏览器/Custom-Tab 授权 → 深链
`h(Uri)` 回 Activity 解析 code/error。

## `r12`/`a70`/`aa8`/`v60`/`yn7`

`r12`=登录 Activity 基类；`a70`/`aa8`=结果 parcelable；
`v60`=WebViewClient（callback 拦截）；`yn7`=深链
action 枚举（LOGIN）。

## 语义

**OAuth Web 登录层** —— Apple=WebView 拦截，Microsoft=
深链回调，GMS=SDK（Phase 1227 manifest）—— 三方登录
全部走 Web 授权页 → 回调 URL 拿 code → token 换同步。

## Harmony 决策

OAuth 登录 → Harmony `Web` 组件/`webview.WebviewController`
拦截 callback_url 重定向 —— Web 授权流语义保真；
GMS 登录 → fail-closed（Harmony 用华为账号或省略）。

## 产出

- fixture `d02-oauth-login.mjs`（10 断言）。
- ADR-1226；中文报告。
