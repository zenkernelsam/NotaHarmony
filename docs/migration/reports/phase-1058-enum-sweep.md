# Phase 1058 报告 — 枚举清扫

## 范围

`im`/`iq0`/`n3a`/`oz9`/`xw9`/`y01`/`z4d`/`z90`/`zsa`/
`ww9`/`t8a` 11 个枚举。纯审计。

## 原版发现

- 评论锚点 im 5 值（CANVAS/TEXT/ENTITY/REPLY）。
- **iq0 纸色稀疏码**：CREAM=1 YELLOW=2 TAN=6 BLUE=7
  WHITE=13 BLACK=15——非连续，迁移禁重排。
- n3a 纸纹 3、oz9 书签、xw9 PDF 盒模式 3（MAX_BOX/
  CROP_BOX/FIT）、y01 位置 4（含 START/END_OF_DOC）、
  z4d 形状定义 4、zsa 位宽 16/32、ww9 STRING/BOOLEAN。
- `t8a` 路径元素 8 值：ATTRIBUTED_{CUBIC,QUADRATIC,LINE,
  MOVE_TO} + NON_ATTRIBUTED_×4（po4 点字段类型）。

## Harmony 决策

枚举码原样保留（含稀疏）。

## 产出

- 证据：`phase-1058-enum-sweep.md`
- Fixture：`d02-enum-sweep.mjs`（12/12）
- ADR-1002；全量 Replay 见本提交。
