# Phase 1061 报告 — 形状定义子表

## 范围

`z5c.a0` 工厂、`uf7`/`pra`/`oz8` 定义表、`pz8` 枚举。
纯审计。

## 原版发现

- 工厂按 z4d ordinal 分派：LINE→uf7{start,cp1,cp2,end,
  arrowHead} 三次贝塞尔+箭头；POLYGON→pra{points 向量}；
  NORMAL_SHAPE→oz8{type:pz8,size:qed}；NONE→null。
- `pz8` 枚举 jadx 只恢复 ELLIPSE——完整值表需外部证据。
- `oz8.k()` byte→枚举越界→首值兜底。
- ao2/le8 `definition` 字段挂此三选一。

## Harmony 决策

定义表+兜底语义保留；pz8 值表待补（fail-closed 记录）。

## 产出

- 证据：`phase-1061-shape-defs.md`
- Fixture：`d02-shape-defs.mjs`（11/11）
- ADR-1005；全量 Replay 见本提交。
