# ADR-1005 — 形状定义子表

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `z5c.a0(z4d)` 工厂：NONE→null、LINE→uf7（贝塞尔+
  arrowHead）、POLYGON→pra（points）、NORMAL_SHAPE→oz8
  （type:pz8+size）、else o14.t()。
- `pz8` 枚举 jadx 仅见 ELLIPSE——**完整值表需 schema/
  新版补全**；`oz8.k()` 越界→get(0) 兜底。
- ao2/le8 `definition` 字段 = 三选一子表。

## Harmony 决策

三定义表保留；pz8 完整枚举值待 schema/新版证据补齐
（fail-closed：未知值→ELLIPSE 兜底与原行为一致）。

## Parity 状态

等价（枚举值表待补证据）。

## 验证

- `d02-shape-defs.mjs`：11/11 通过。
