# ADR-0993 — 块/位置/删除操作载荷

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `rl2` CreateBlock 21 toString 字段（type/corner/几何/
  textWrap/image/crop/webUrl/mathLatex/mathColor/paper/
  翻转/fitText/margins/锁定）。
- `td8` ModifyBlock 16 字段+blocks>0；`je8`
  ModifyPositions>0；`s83` DeleteEntities 软删除/
  恢复四列表。
- 枚举：`cz0`{TEXT,IMAGE,MATH}、`ty0`{SQUARE,ROUND}、
  `ive`{PIXEL_ALIGN,NO_WRAP}。

## Harmony 决策

字段/校验/枚举逐条保留；删除-恢复模型对齐。

## Parity 状态

等价。

## 验证

- `d02-block-ops.mjs`：12/12 通过。
