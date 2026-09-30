# Phase 1135 证据 — e4c 删除/快照/批量读 API

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `e4c.A(Integer)→Boolean` = 位置墓碑检查

```java
num!=null → swc = au1.g1(num.int, e.g)   // pos→cursor
         → exc = swc.d(new hr5())         // 锚
return xj2.f(exc, this.g.I)               // tombstone map→Boolean
```

"位置 i 的字符是否已删" —— 编辑器删除态查询。

## `e4c.a()→m4c` = 规格快照重建

```java
l4c2 = new l4c(k4c.c(mha), k4c.b?.k(), l4c.c)   // 布局规格
bxc  = iwc.c()                                  // 文本 spec
return m4c.D(b, m, n, h, c(list), l4c2, bxc,
             f.build()/*hja*/, g.a()/*cl2*/, 4225)
```

live→spec 循环（同 v69.b 对 a79）。

## `e4c.f(List)→List` = 阻塞批量应用

```java
x90.J0(yn7.MODEL, p4c.Play,
       ijg.r0(200, dr3.MILLISECONDS),   // 200ms 超时
       j79(24, this, list))
```

`runBlocking` + 200ms `withTimeout` 的批量 op 应用
（kotlinx `t3i`/`ijg`/`dr3`/`x90`/`j79`）。

## `e4c.h(...)` = 静态文本抽取→s3c

StringBuilder 内容 + `gxc` 线锚 + `mnb` 槽 → `mz0`
（`hnb.I` 时包装）→ `new s3c(set2, set3, mz0, e4c.p, i,
exc, hr5)` 入 `or5` 布局。

## `e4c.c()→int` / `d()→nr5`

`c()=iwc.g.d()` 墓碑/总数；`d()=k4c.b(or5)` 布局引擎。

## Harmony 决策

- 删除态查 = pos→cursor→锚→tombstone map。
- 快照 = live→spec 重建；批量 = 200ms 超时阻塞。
- Harmony：删除检查同样三步；批量用 async 超时。

## 产出

- fixture `d02-delete-read.mjs`（10 断言）。
- ADR-1079；中文报告。
