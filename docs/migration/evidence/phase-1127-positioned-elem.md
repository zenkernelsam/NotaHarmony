# Phase 1127 证据 — xwc 定位元素 + g2c 向量适配 + f2c 表

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `ywc` = 定位元素基类

```java
abstract ywc { Integer a;             // 位序
  abstract qo5 a();                    // opId
  Integer b() → a }
```

## `xwc extends ywc` = 定位序列元素

```java
xwc { qo5 b;    // opId
      g2c c;    // 元素列表（List）
      long d }  // 位序
a()→b; c()→c(g2c 即 List)
```

## `g2c extends hvd` = FlatBuffers 向量→List 适配

```java
g2c(f2c table) → hvd
d() → f2c.j();            // count
e(i, cxc) → f2c.l(i,cxc)  // 绑读第 i 个 cxc 项
```

`f2c` = 序列树元素的 FlatBuffers 表（`cxc` 项向量）。
`hvd` = FB 向量→只读 List 适配（Phase 1093）。

## 链路

`f2c`(wire 表) → `g2c`(向量适配 List) → `xwc`(定位元素
{opId,items,pos}) → `uwc`/`ywc` 应用记录 —— 序列树元素
从 wire 到内存的完整链。

## Harmony 决策

- 定位元素 = `{opId, List(items), pos}`。
- items 经 FB 向量懒绑 List 暴露；`e(i,obj)` 绑读直写出参。

## 产出

- fixture `d02-positioned-elem.mjs`（10 断言）。
- ADR-1071；中文报告。
