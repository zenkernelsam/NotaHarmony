# ADR-0885 — td8 ModifyBlock 字段图

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

18 槽：blocks 向量 + 与 Create 同构的修改集——
rotation/scale/cropRect/paper/mathLatex/
mathColor **setter-wrapped**；flip/resize/lock/
caption **Boolean 三态**。**无 margins/type/
image/webUrl**（创建后不可变）。

## Harmony 决策

Modify 语义对齐：setter 包装 + 三态 + 不可
变字段缺席。

## Parity 状态

等价。

## 验证

- `d02-td8-block.mjs`：19/19 通过。
- 全量 Replay 814 文件绿，见 Phase 941 提交。
