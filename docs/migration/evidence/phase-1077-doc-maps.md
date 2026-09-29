# Phase 1077 证据 — v69 实体表名册 + ba6.j 全知检查 + xhe

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `v69` 实体/集合表名册（访问器→因果集合）

| 访问器 | 类型 | 基类 |
|--------|------|------|
| `i()` | `uia` | vz（set） |
| `k()` | `aja` | via（map） |
| `l()` | `bja` | vz（set） |
| `n()` | `aja` | via（map） |
| `p()` | `bja` | vz（set） |
| `r()` | `qja` | jja（map，`r().I` 内层） |

## `ba6.j(v69, List<qo5>, z)` = 全实体已知检查

```java
for id in list:
    if !l().contains(id) && !p() && !i() && !n() && !k()
       && (!z || !r().I.contains(id)):
        return false          // 任一表都无 → 未知实体
```

MODIFY_POSITIONS 前置：`ba6.j(v69, fsi.K(op), fsi.P(op))`——
所有目标实体必须在五表之一（z 时含 r 的 tombstone 集）。

## `xhe extends oy0, be5, ce5` = 墨/路径实体接口

`whe` 伴生；`wy0 instanceof xhe` 特例（1072）。

## Harmony 决策

- 文档根持六张因果集合表；apply 前 `ba6.j` 全知校验
  （缺实体 → "Inconsistent logic" 遥测）。

## 产出

- fixture `d02-doc-maps.mjs`（10 断言）。
- ADR-1021；中文报告。
