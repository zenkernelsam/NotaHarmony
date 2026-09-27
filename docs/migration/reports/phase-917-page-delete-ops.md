# Phase 917 报告 — ge8/s83/je8/tdf 四表实名

## 范围

页面修改/实体删除/批量位移/瞬态结束 op 实名。

## 原版发现

- ge8=ModifyPage：pages cxc[]+moveTo lxc+background
  m2d+bookmarked oz9 单 op 混合。
- s83=DeleteEntities：实体 qo5[] + 页面 cxc[] 双墓碑对
  （删除/复活各一向量，同步可逆软删除）。
- je8=ModifyPositions{ie8[]}；tdf=TransientInteractionEnded
  {interactionId 必填, replacedByOp}——sdf↔tdf 成对。

## Harmony 核对

编码对齐。

## 产出

- 证据：`phase-917-page-delete-ops.md`
- Fixture：`d02-page-delete-ops.mjs`（18/18）
- ADR-0861；全量 Replay 790 文件绿。
