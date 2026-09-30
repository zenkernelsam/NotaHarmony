# Phase 1187 证据 — a76 int-rect + r93 Density iface（视口几何/单位）

来源：`defpackage/{a76,r93}.java`。

## `a76` = int 矩形 `{a=l, b=t, c=r, d=b}`

```java
c() = d-b            // height
f() = c-a            // width
e() = l<<32 | t      // 打包左上点（long）
d() = w<<32 | h      // 打包尺寸
b() = (cy&0xffffffff)|(cx<<32)  // 打包中心点
```

int rect + long 打包访问器 —— `ViewportState` 的功能/可视
视口字段（`functionalViewportRect`/`visibleViewportRect`）。

## `r93` = **`Density` iface**（密度/单位换算）

```java
B(long)→float        // 打包 long→dp？
C0(float)→int
j0(float)→float      // 换算核心
cl3.c(long)/b(long)  // long→两 float 拆包
Float.floatToRawIntBits   // 位打包
ds4.a float[] consts
```

Compose `Density` 风格：dp↔px/sp 单位换算（`ViewportState.
density` 字段对应）。

## 判定

视口几何层：`a76` int-rect（像素/文档坐标 bounds）+
`r93` Density（dp↔px 换算）—— `ViewportState` 的
`functionalViewportRect`/`visibleViewportRect`=`a76`，
`density`=`r93`。

## Harmony 决策

- `a76` → Harmony `Rect`/`common2d.Rect`（int bounds +
  点/尺寸打包 helpers）。
- `r93` Density → Harmony `vp`/`px` 换算（`display`/`UIContext`
  `vp2px`）。

## 产出

- fixture `d02-rect-density.mjs`（10 断言）。
- ADR-1131；中文报告。
