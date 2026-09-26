# ADR-0810 — 赢家寄存器契约（fqb/do6/xj2/so5.a/fsi.J）

## 状态

accepted（文档+fixture，无源改动；Harmony 侧先前已等价移植）

## 原版契约（`decompiled_1.0.3`）

- `fqb` 赢家单元 = {winnerId qo5, winnerValue, winnerClock xgb}；
  `c(op, value)` 为 LWW 提议：仅当 `so5.a(newId, winnerId) > 0`
  时覆盖。`yc6` discriminant-14 为冻结形态（J/K/L 三槽）。
- `do6.g` 把冻结寄存器包成 `fqb` builder（vz9 Page builder 使用）；
  `xj2.v/w` 读侧返回赢家值；`xj2.k` 包或建空寄存器。
- `so5.a` op-id 比较器：timestamp **u32 无符号**比较 +
  site u16 无符号比较；与 `exc.A0`（有符号减法 + index 倒序项）
  职责不同 —— 后者排实体位置，前者定寄存器胜者。
- `fsi.J(op)` = 挂钟（serverTime 优先，否则 clientTime），存 xgb
  仅作辅助，不参与排序。
- `fsi.K(op)` = 按 payload 类型分派的触及实体清单。

## Harmony 决策

持久化式等价：`winner_timestamp`/`winner_site_id` 列存赢家 op-id
两半（u32/u16 number 比较 = 无符号语义），覆盖条件
`compareOperationIdentity > 0` 即 `so5.a > 0`。挂钟列不落盘 —
— 原版亦仅作辅助。Recording name/segments/z_index、page
background/bookmark/pageInAsset 均按此模式物化。

## Parity 状态

等价（LWW 键序一致；xgb 辅助挂钟裁剪已登记）。

## 验证

- `d02-winner-register-contract.mjs`：20/20 通过。
- 全量 Replay 与双 HAP 构建见 Phase 866 提交。
