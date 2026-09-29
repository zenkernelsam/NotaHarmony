# Phase 1073 证据 — 实体接口层级（be5→qsa→xy3→具体类别）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 接口继承链

```
be5          变换源（Phase 1062：origin/rot/scale/page/zIndex）
  ↑ extends
qsa extends be5   void d(uq9, ie8)   ← **apply 方法**
  ↑ extends
xy3             yy3 build()          ← materialize→快照
  ↑ extends
o06 / k5d / wy0   (各 extends xy3,qsa)  三大实体类别
fkb implements yjb, xy3              另一类别
```

## 类别→实体推断

`v69` 的 `t()/u()/s()` 分别持 `o06`/`k5d`/`wy0`：

| 类别 | 对应 live | spec |
|------|-----------|------|
| o06 | m5d(形) 等 | n5d |
| k5d | qy0(块) | ry0 |
| wy0 | xhe 子类（墨/文） | — |

`wy0 instanceof xhe` 特例 + `fkb`(yjb) = 文本/墨类别。

## `yy3` = 不可变实体快照（`xy3.build()` 产物）

`fkb.build()→yy3`；物化侧把活实体固化。

## Harmony 决策

- 实体能力分解：be5(变换) + qsa(应用) + xy3(快照) +
  类别接口；各类别表独立索引。

## 产出

- fixture `d02-entity-hierarchy.mjs`（10 断言）。
- ADR-1017；中文报告。
