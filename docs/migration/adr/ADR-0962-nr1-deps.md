# ADR-0962 — nr1 依赖名册

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `qr1` = 双 `pce` 懒 File 提供器（files+cache dir）。
- `jl3` = {pce×2, sfb Flow} + cx6 dep——连接状态
  Flow 持有（`b()→hl3`）。
- `sxa` = Context-only 系统服务 wrapper（connectivity
  推断）。
- `ssf` = {q75,xrf,vs4,pce} 4-dep 服务。
- `v2f` = {t2f} 时钟（Phase 1000）。

## Harmony 决策

`qr1`→context filesDir/cacheDir；`jl3`/`sxa`→
`@kit.NetworkKit` connection 模块；`ssf` 后续展开。

## Parity 状态

依赖语义等价（推断标注）。

## 验证

- `d02-nr1-deps.mjs`：10/10 通过。
