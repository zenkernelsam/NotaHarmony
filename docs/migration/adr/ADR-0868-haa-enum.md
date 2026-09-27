# ADR-0868 — `haa` payload-type 枚举全集

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `haa` = 32 值 payload-type 枚举（NONE@0 →
  MODIFY_COMMENT@31），序数与 zq9 注册序一致。
- `uq9.m()` 读法：越界→NONE 回退（nz3 模式）；
  Harmony fail-closed 抛错为已记录分歧（ADR-0850）。

## Harmony 决策

OpTypes 序数表对齐 32 值全集；未知类型拒绝
（fail-closed，防畸形回放）。

## Parity 状态

等价+已记录分歧（unknown→NONE vs throw）。

## 验证

- `d02-haa-enum.mjs`：63/63 通过。
- 全量 Replay 797 文件绿，见 Phase 924 提交。
