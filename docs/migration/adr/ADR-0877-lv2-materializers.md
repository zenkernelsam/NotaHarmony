# ADR-0877 — `lv2` 物化器登记

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

`lv2` 承载全部线型向量物化器：29 个方法覆盖
ink/group/text/page/block/recording/collab/
bundle 各表的向量字段；统一
`m18.S()` 构建→逐元素读→`m18.E` 冻结→
`hw3.I` 空表哨兵模式。`th7` 返回 = 可变
RandomAccess 表（热路径），`List` = 冻结表。

## Harmony 决策

物化语义对齐（空表哨兵 + 冻结表）。

## Parity 状态

等价。

## 验证

- `d02-lv2-materializer-registry.mjs`：32/32 通过。
- 全量 Replay 806 文件绿，见 Phase 933 提交。
