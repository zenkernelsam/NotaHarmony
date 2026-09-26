# Phase 866 报告 — 赢家寄存器契约登记

## 范围

登记原版 LWW 寄存器核心：`fqb` 赢家单元、`do6` builder 包装、
`xj2` 读侧助手、`so5.a` op-id 比较器、`fsi.J` 挂钟提取；
核对 Harmony winner_* 持久化等价。纯审计阶段，无源改动。

## 原版发现

- `fqb.c(op, value)`：仅当新 op-id 按 `so5.a` 排序更大才覆盖 —
  — LWW 键是 op-id 而非挂钟；挂钟（serverTime 优先）仅存 xgb
  辅助。
- `so5.a`：timestamp u32 无符号 + site u16 无符号 —— 与
  `exc.A0` 的位置排序（含 index 倒序项）是两个不同比较器。
- `yc6`-14 冻结形态：J=赢家 opId、K=赢家值、L=赢家 xgb。
- `vz9` builder 经 `do6.g` 包装三寄存器，build 时冻结回 `wz9`。

## Harmony 核对

`compareOperationIdentity` 与 `so5.a` 逐项等价；`winner_*` 列
持久化赢家 op-id，`> 0` 覆盖语义一致。xgb 挂钟裁剪登记为
形态差异。

## 产出

- 证据：`phase-866-winner-register-contract.md`
- Fixture：`d02-winner-register-contract.mjs`（20/20）
- ADR-0810；全量 Replay 与双 HAP 结果记录于提交。
