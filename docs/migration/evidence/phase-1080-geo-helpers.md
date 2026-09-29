# Phase 1080 证据 — ba6.K tombstone + h0 平移 + i() 矩形旋转

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `ba6.K(qo5, map)` = tombstone 判定

```java
return o(map.get(id), Boolean.TRUE);   // map 存 Boolean 墓碑标志
```

## `ba6.h0(k11 bounds, fqa off)` = 包围盒平移

```java
return k11{a+off.c, b+off.d, c+off.c, d+off.d};
```

## `ba6.i(cmb rect, float w, float h, int deg)` = 页旋转矩形

```java
0   → rect
90  → cmb{b, h-c, d, h-a}
180 → cmb{w-c, h-d, w-a, h-b}
270 → cmb{w-d, a, w-b, c}
else→ 遥测 "Unsupported PDF rotation"(rotation.deg=i) + 原样
```

`cmb{a,b,c,d}` = rect（左/上/右/下）；`w`/`h` = 页尺寸。

## Harmony 决策

- tombstone = map 中 Boolean 标志（独立删除标记表）。
- 页旋转按度数公式（仅 0/90/180/270；其余遥测+原样返回
  —— fail-soft 不崩）。

## 产出

- fixture `d02-geo-helpers.mjs`（10 断言）。
- ADR-1024；中文报告。
