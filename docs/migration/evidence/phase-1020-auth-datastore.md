# Phase 1020 证据 — xrf 鉴权 DataStore

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `xrf extends hq8`（Preferences DataStore）

```java
public final class xrf extends hq8 {
    public static final eua k = new eua("dataVersion");
    public static final eua l = new eua("authToken");
    public static final eua m = new eua("emailToDeviceIds");
    public static final eua n = new eua("currentUserEmail");
    public static final eua o = new eua("currentUserId");
    public static final List p = m18.m0(new prf(), new qrf());
    // g/h/i/j = pce lazy getters
    public xrf(Context);
}
```

## 鉴权键

| `eua` 键 | 值 | 说明 |
|---|---|---|
| `dataVersion` | int | store schema 版本 |
| `authToken` | String | 会话 token |
| `emailToDeviceIds` | String | email→deviceId 映射（JSON） |
| `currentUserEmail` | String | 当前用户 email |
| `currentUserId` | String | 当前用户 id（ttf） |

## `p` = 迁移序列化器链

- `m18.m0(prf, qrf)` —— 两个 DataStore migration
  （旧 SharedPreferences 迁移？）。

## `hq8` = Preferences DataStore 基类

- `eua` = Preferences.Key wrapper；
  `pce` lazy 提供器 ×4 = key→Flow 映射。

## HarmonyOS 决策

- DataStore → `@ohos.data.preferences`/`relationalStore`
  等价；键名+结构保留。
- `authToken`/`currentUser*` 是 **鉴权敏感**——
  Harmony 侧需加密存储（AssetStore/KeyStore）；
  整体鉴权仍 fail-closed（OAuth 不可复现）。

## 产出

- fixture `d02-auth-datastore.mjs`（10 断言）。
- ADR-0964；中文报告。
