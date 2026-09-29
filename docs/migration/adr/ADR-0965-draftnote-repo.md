# ADR-0965 — hl3 DraftNote DAO + jl3 仓储（1018 修正）

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `hl3` = DraftNote Room DAO（x5c+wp1 binder+sh8），
  `DELETE ... IN(Collection)` 批量。
- `jl3` = **DraftNote 仓储**——`b()→hl3`+pce×2+sfb
  Flow+cx6 dep（Phase 1018 误为"连接 Flow"）。
- `vs4` = 遥测 logger（`a()`发 `yn7.LOGIN`）。
- `q75` = {vs4,dt4,cx6} 鉴权上层；`cx6` = 检查 iface。

## Harmony 决策

DraftNote 仓储等价平移；`vs4` 遥测点位保留。

## Parity 状态

等价（修正后）。

## 验证

- `d02-draftnote-repo.mjs`：10/10 通过。
