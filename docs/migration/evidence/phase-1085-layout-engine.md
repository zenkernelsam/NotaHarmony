# Phase 1085 证据 — m4c 布局细节 + nr5 布局引擎 + bxc

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `m4c` 13 字段 ctor（集合 spec 布局）

```java
m4c(int b, vy7 c margins, Float d, int e, bool f,g,
    List h, double i, l4c j, bxc k, hja l, cl2 m, List n)
p = l4c.b ?: qr5.a        // 缺省 nr5
o = pce(lazy aub(this,3))
```

## `l4c implements j4c` = 布局持有

`{mha a, nr5 b, double c}`。

## `nr5 extends mxc` = **布局引擎**接口

```java
mr5 a(mr5 in);      // relayout
mr5 b();
or5 builder();      // 增量构建器
```

`mr5`/`or5`/`mxc` = 布局输入/构建器/基接口。

## `bxc implements jxc,bf0` = 块详情（持 `sia` 空间索引常量）

`{k5c b}; static sia v`。

## Harmony 决策

- 集合 spec 布局参数全保留；`nr5` 布局引擎抽象
  （Harmony 用等价排版器）。

## 产出

- fixture `d02-layout-engine.mjs`（10 断言）。
- ADR-1029；中文报告。
