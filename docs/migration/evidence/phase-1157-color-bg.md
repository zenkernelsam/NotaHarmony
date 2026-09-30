# Phase 1157 证据 — hu1 Color + tu1 色门面 + nz9 背景

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `hu1 extends xwd implements ka4` = `core.flatbuffers.Color`

```java
a()→String; c()/d()/e()→byte×3(+1)  // 名 + RGBA byte
```

RGBA byte×4 struct —— `sg5` `COLOR` schema 的实现类。

## `tu1` = 色门面

```java
static pce a = pce(ra(13))           // 懒默认色
a(float r,g,b,a)→hu1                  // float→Color 打包
b(hu1)→int                            // Color→int
c(int)→hu1                            // int→Color 解包
```

float RGBA↔`hu1` 结构互转 + 懒默认（`ra(13)`）。

## `nz9 extends cee implements ka4` = `core.flatbuffers.
PageBackground`

`a()→String` 名 —— 页背景表（`a79.Q` 的类型）。

## `vv7.f`/`fag.k` = 背景工厂

`vv7.f(..., qed N, ..., 54)→nz9` 产默认页背景；
`fag.k(null,null,null, hu1 tu1.a, null,111)` 产背景元素
（`hu1` 色 + 掩码）。

## 语义

- `hu1` = Color `{r,g,b,a:byte}`；`tu1` = float↔Color
  打包门面 + 默认色。
- `nz9` = PageBackground 表；`vv7`/`fag` = 背景构建
  （色 + 尺寸 + 掩码）。

## Harmony 决策

- Color = RGBA byte 结构；float↔byte 打包；页背景表
  `{color, size, pattern}`。
- Harmony：`{r,g,b,a}` + PageBackground。

## 产出

- fixture `d02-color-bg.mjs`（10 断言）。
- ADR-1101；中文报告。
