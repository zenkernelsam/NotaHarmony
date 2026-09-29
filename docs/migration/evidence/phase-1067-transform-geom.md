# Phase 1067 证据 — y18 矩阵 + k11 包围 + v09 实体类别

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `y18` = 4×4 浮点变换矩阵（androidx Matrix vendored）

```java
float[] a;                       // 16 元素
a() → {1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1}   // 单位阵
b(float[] m)                     // 矩阵乘
l / h / i                        // translate / rotate / scale
                                 // （Phase 1062 be5.P 用）
```

## `k11` = 4-float 包围盒

`{a,b,c,d}` = left/top/right/bottom 式包围盒（`be5.G()` 返回，
`be5.y()` 重建）。

## `v09` = 实体类别枚举（4 值）

```java
ANIMATION, INK, SHAPE, BLOCK
J = setOf(INK, SHAPE, BLOCK)     // x90.W0
```

- `be5.f()→v09` = 实体种类判别。
- `J` = **可变换集合**：INK/SHAPE/BLOCK（ANIMATION 除外——
  动画是过渡态，不是可变换实体）。

## Harmony 决策

- `y18` 4×4 矩阵原样（列主序乘法）。
- `v09` 类别枚举 + 可变换子集。

## 产出

- fixture `d02-transform-geom.mjs`（10 断言）。
- ADR-1011；中文报告。
