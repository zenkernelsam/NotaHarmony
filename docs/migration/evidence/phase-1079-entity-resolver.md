# Phase 1079 证据 — ba6.R 实体→be5 解析器

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `ba6.R(qo5, map..map5, z, z2) → be5?`

```java
if (!z2 && K(id, map2)) return null;     // tombstone → null
if (z):
    ly3 = K(id,map2) ? null : map.get(id) as ly3;
    if ly3 instanceof be5 → return       // 主表直接命中
ly3 = (s06)map3.get(id) ?: (m4d)map4.get(id) ?: (ly3)map5.get(id)
```

- `K(qo5,map2)` = **tombstone 检查**（被删实体→null）。
- `map` = 主实体表（ly3/be5 快照）；`map3`=`s06`、
  `map4`=`m4d`（spec 接口！）、`map5`=`ly3`。
- `m4d` = Phase 1065 n5d 的 spec 接口 —— spec 也是 be5。

## 角色推断

- `s06`/`m4d`/`ly3` = spec/快照实体（可作 be5 变换源）。
- `R` 在 5 张类别表间回退解析实体为变换源。

## Harmony 决策

- 实体解析 = tombstone 短路 + 类别表回退链；
  spec（m4d）同样可作变换源（初始态包围盒）。

## 产出

- fixture `d02-entity-resolver.mjs`（10 断言）。
- ADR-1023；中文报告。
