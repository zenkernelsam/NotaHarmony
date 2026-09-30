# Phase 1125 证据 — qwc/rwc 序列树游标 + swc 接口

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `swc` = 序列树游标接口

```java
{ a() → qwc;      // 固化不可变
  c() → long;     // 位序（f8d.c）
  d(hr5) → hr5;   // 读锚点到 hr5
  e(rwc) → rwc }  // 转可变游标
```

## `qwc implements swc` = 不可变游标

```java
qwc { f8d a; int b }          // 节点 + 槽位
a()→this; c()→a.c;
d(hr5) → a.a(hr5, b);         // f8d.a 在槽位 b 写锚点
e(rwc) → {a, b} 灌进 rwc      // 不可变→可变
static qwc c                  // 共享空
```

## `rwc implements swc` = 可变游标

```java
rwc { f8d a; int b = -1 }     // 可变字段
d(hr5): a==null → ba6.d0("sharedData") throw  // 未绑校验
      else a.a(hr5, b)
a() → qwc                     // 可变→固化
```

## `mxc` = 标记 iface

- 双游标 = 同一位置抽象的 immutable(qwc)/mutable(rwc) 两态。
- `njj.O`/`njj.Q` 用 qwc 做锚点→节点查找。

## Harmony 决策

- 树游标 = `{node, slot}` 双态（冻结/可变）；`d(hr5)` 为
  锚点出参读法。Harmony：同一 cursor 对象 + freeze 标志即可。

## 产出

- fixture `d02-tree-cursors.mjs`（10 断言）。
- ADR-1069；中文报告。
