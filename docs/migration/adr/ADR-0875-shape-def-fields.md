# ADR-0875 — 形状定义表字段布局

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `uf7` Line：start@f0 **必需**、cp1@f1、cp2@f2、
  end@f3（均 fqa inline）、arrowHead@f4 z90 枚举
  {NONE,SINGLE}。
- `pra` Polygon：points@f0 = fqa[8B] 向量。
- `oz8` NormalShape：type@f0 `pz8`={ELLIPSE=0}
  （1.0.3 唯一预置形）、size@f1 qed **必需**。
- 枚举字段均范围校验回退元素 0。

## Harmony 决策

形状定义布局对齐；必需字段缺省应拒绝解析。

## Parity 状态

等价。

## 验证

- `d02-shape-def-fields.mjs`：11/11 通过。
- 全量 Replay 804 文件绿，见 Phase 931 提交。
