# Phase 930 报告 — 形状定义多态全链实名

## 范围

CreateShape definition 分发链闭合。纯审计。

## 原版发现

- z4d=ShapeDefKind{NONE,LINE,POLYGON,NORMAL_SHAPE}；
  z5c.a0 工厂序数→uf7/pra/oz8。
- uf7=Line(贝塞尔+箭头)、pra=Polygon、
  oz8=NormalShape(type+size)。
- z5c.Z=cxc "{site},{ts},{idx}" 字符串化。

## Harmony 核对

分发结构对齐。

## 产出

- 证据：`phase-930-shape-defs.md`
- Fixture：`d02-shape-defs.mjs`（8/8）
- ADR-0874；全量 Replay 803 文件绿。
