# Phase 1018 报告 — nr1 依赖名册

## 范围

nr1 剩余依赖 ssf/qr1/jl3/sxa 结构钉扎。纯审计。

## 原版发现

- `qr1` = 双 `pce` 懒 File 提供器（files+cache dir）。
- `jl3` = Flow 持有连接状态（`b()→hl3`+cx6 dep）。
- `sxa` = Context-only 系统服务 wrapper。
- `ssf` = {q75,xrf,vs4,pce} 4-dep 服务。

## Harmony 决策

`qr1`→filesDir/cacheDir；`jl3`/`sxa`→NetworkKit
连接模块。

## 产出

- 证据：`phase-1018-nr1-deps.md`
- Fixture：`d02-nr1-deps.mjs`（10/10）
- ADR-0962；全量 Replay 见本提交。
