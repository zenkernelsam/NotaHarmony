# Phase 1023 证据 — xrf 鉴权 DataStore 迁移链

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `hq8` = DataStore 基类

- `we2 a`（datastore）+ `CountDownLatch` + `kt2`
  ——异步初始化 + 属性委托 `fl6`。
- `eua` = Preferences.Key{name}+equals/hashCode。

## `prf` = **v1→v2 迁移（鉴权清除）**

```java
b(obj, lx):
    tk8 c = gua.c();
    c.f(xrf.l);            // 删 authToken
    c.f(xrf.m);            // 删 emailToDeviceIds
    c.f(currentUserEmailHash);
    c.g(xrf.k, 2);         // dataVersion=2
c(ef2, obj): dataVersion < 2 ? apply
```

- **v2 = 强制再登录**——清空 token+设备映射+
  email 哈希。

## `qrf` = **v2→v3 迁移（emailToDeviceIds 格转）**

```java
b(obj, lx):
    tk8 c = gua.c();
    c.g(xrf.k, 3);         // dataVersion=3
    // 迭代 emailToDeviceIds set, 正则
    //   "email":"([^"]+)"  提取 → 格转
```

- 从 Set<String> 解析 email JSON 格式→新格式。

## 版本历史

| dataVersion | 变化 |
|---|---|
| 0/1 | 初始 |
| 2 | 清 authToken+emailToDeviceIds+emailHash |
| 3 | emailToDeviceIds JSON 格转 |

## `tk8`/`gua` = DataStore 数据图

- `gua` = Preferences 实例；`tk8` = 可变副本
  （`f`删/`g`写/`a`Map）。

## HarmonyOS 决策

- 迁移链保留（v2 清 auth 语义重要）；Harmony
  preferences 初始化时按 dataVersion 应用
  两迁移；邮箱 JSON 格转正则保留。
- 鉴权数据本身 fail-closed（OAuth）。

## 产出

- fixture `d02-auth-migrations.mjs`（11 断言）。
- ADR-0967；中文报告。
