# ADR-0878 — 类型枚举与资产包装表

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `t16`=StrokeStyle{VARIABLE_WIDTH,FIXED_WIDTH,
  DASH,DOTS}；`ty0`=CornerStyle{SQUARE,ROUND}；
  `cz0`=BlockType{TEXT,IMAGE,MATH}。
- `dp5`=ImageAsset{metadata:wa0 必需,
  size:qed 必需}；`akb`=RecordingAsset
  {metadata:wa0 必需}。

## Harmony 决策

枚举序数与资产表布局对齐；必需字段缺失拒绝。

## Parity 状态

等价。

## 验证

- `d02-type-enums-assets.mjs`：8/8 通过。
- 全量 Replay 807 文件绿，见 Phase 934 提交。
