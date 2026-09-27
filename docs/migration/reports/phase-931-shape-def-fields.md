# Phase 931 报告 — 形状定义表字段级布局

## 范围

`uf7`/`pra`/`oz8` 访问器→偏移精确钉死。纯审计。

## 原版发现

- `uf7` Line：start@c(4) **必需** + cp1@c(6) +
  cp2@c(8) + end@c(10) + arrowHead@c(12)
  （z90={NONE,SINGLE}）。
- `pra` Polygon：points@c(4) = fqa 8B 向量。
- `oz8` NormalShape：type@c(4)（pz8={ELLIPSE}，
  1.0.3 唯一预置形）+ size@c(6) qed **必需**。

## 产出

- 证据：`phase-931-shape-def-fields.md`
- Fixture：`d02-shape-def-fields.mjs`（11/11）
- ADR-0875；全量 Replay 804 文件绿。
