# Phase 1061 证据 — 形状定义子表（z5c.a0 工厂）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `z5c.a0(z4d)` = 形状定义工厂

```java
ordinal 0 (NONE)        → null
ordinal 1 (LINE)        → new uf7()
ordinal 2 (POLYGON)     → new pra()
ordinal 3 (NORMAL_SHAPE) → new oz8()
else → o14.t() 不可达
```

## 定义子表字段（toString 实名）

| 类 | 字段 |
|---|---|
| `uf7` Line | `{start, controlPoint1, controlPoint2, end, arrowHead}`——三次贝塞尔+箭头 |
| `pra` Polygon | `{points:fqa[]（lv2.a0 向量）}` |
| `oz8` NormalShape | `{type:pz8, size:qed}` |

## `pz8` = NormalShape 类型枚举

jadx 仅反编出 `ELLIPSE=0`（其余值丢失在 static init）；
`nz3 J` EnumEntries + `pz8.a()` 访问器；
`oz8.k()` 读 byte→枚举（越界→get(0) 兜底）。

## 挂载点

`ao2`/`le8` 的 `definition` 字段（cee 子表，z5c.w 读）
= 三选一（Line/Polygon/NormalShape）。

## Harmony 决策

- 三定义表字段保留；pz8 枚举**重建需查 schema/新版
  源码补全**（jadx 丢失）；越界→首值兜底保留。

## 产出

- fixture `d02-shape-defs.mjs`（11 断言）。
- ADR-1005；中文报告。
