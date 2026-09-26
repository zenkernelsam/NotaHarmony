# 原版 1.4.2 Passkey/SSO 与 API 门控 Firebase 登记（Phase 771 证据）

> 日期：2026-09-29（Asia/Shanghai）
> 证据源：`decompiled_1.4.2/sources/com/gingerlabs/notability/data/user/`、
>   `app/ApiGatedFirebaseInitProvider.java`、`androidx/credentials/`、
>   `resources/res/values/strings.xml`
> 性质：1.4.2 版本差证据登记（ADR-0659 账号边界 + ADR-0708 版本差细化）；
>   无 Harmony 代码变更。

## 一、Passkey 表面（`androidx.credentials` CredentialManager）

字符串键族（1.0.3 无此族）：

```text
feature_login__sign_in_with_passkey = "Sign in with a passkey"
feature_login__passkey_no_credential / _sign_in_error / _sign_in_rejected / _unavailable
feature_settings__add_passkey / passkey_added / passkey_already_added
feature_settings__passkey_no_create_option = "set a screen lock on this device"
feature_settings__passkey_verify_error / passkey_unavailable
sso_web_client_id（SSO 客户端 id 配置键）
sign_in_with_email（并行保留邮箱路径）
```

语义：登录屏新增 passkey 入口；设置屏提供"Add a passkey"管理；
`no_create_option` 文案证明系统级屏幕锁是创建前置条件——
即走 Android CredentialManager API 的设备通行密钥。

## 二、异常族（`data/user/`）

- `MalformedPasskeyPayloadException` — 服务端返回负载畸形
- `PasskeyActivityGoneException` — 认证 Activity 中途销毁
- `SsoVerificationException` — SSO 校验失败
- `NullAuthTokenException` — 令牌缺席

引用方：`alc`/`zum`/`kk9`/`xnj`/`o3n`/`fq9`/`p9`（登录与设置流）。

## 三、`ApiGatedFirebaseInitProvider`

```java
public final class ApiGatedFirebaseInitProvider extends jb5 {
  public final boolean onCreate() {
    if (!ib5.a) return false;   // API 门控：未达标直接跳过 Firebase init
    super.onCreate();
    return false;
  }
}
```

Firebase 初始化被 server/API 配置门（`ib5.a`）闸住——1.4.2 将
Crashlytics/Analytics 初始化改为可远端关闭。

## 四、Harmony 分类

- **Passkey/SSO**：双绑定边界——GingerLabs 认证后端 +
  androidx.credentials API；Harmony 侧需 Account Kit/认证服务
  另行评估，无后端即无移植对象。维持 ADR-0659 账号边界
  fail-closed。
- **ApiGatedFirebaseInitProvider**：Firebase/Crashlytics 属 GMS 簇，
  fail-closed；但"初始化可被远端门控"的模式值得登记为
  架构注记（未来 Harmony 分析组件可借鉴 API 门控初始化）。
