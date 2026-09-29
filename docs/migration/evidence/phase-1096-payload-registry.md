# Phase 1096 证据 — zq9.a 载荷类→op 类型注册表

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `zq9.a` = `Map<KClass, haa>`（载荷类→op 反查）

```java
mx7 a = new mx7();
npb k = mpb.a;                          // KClass 工厂
a.put(k.b(l2d.class), haa.SET_METADATA);
a.put(k.b(ra0.class), haa.ASSET_CLOUD_PERSISTED);
a.put(k.b(ln2.class), haa.CREATE_PAGE);
a.put(k.b(ge8.class), haa.MODIFY_PAGE);
…                                       // 31 条 haa 条目
```

- 31 个注册（op 1..31；NONE 无载荷不注册）。
- **与 `z5c.x`（ordinal→class）互为反向** —— 序列化端
  按类查 op-type；反序列化端按 op-type 查类。

## `npb` / `mpb.a` = KClass 工厂

`npb.b(Class)→oj6`（Kotlin `KClass` 轻量反射）；`a(sy4)=sy4`。

## `mx7 implements Map,Serializable,lk6` = 双数组开放 map

`{Object[] I,J 键值, int[] K,L 哈希/链, int M,N}` —— Kotlin
`LinkedHashMap`/`CompactHashMap` vendored 实现。

## Harmony 决策

- 载荷注册表双向：`z5c.x`（type→class）+ `zq9.a`（class→type）。
- `mx7` 紧凑 map 实现。

## 产出

- fixture `d02-payload-registry.mjs`（10 断言）。
- ADR-1040；中文报告。
