# Phase 1035 报告 — Kotlin 协程原语

## 范围

`sfb`/`ml4`/`s7d`/`cz4`/`em8`/`fm8` 原语；修正 1019。
纯审计。

## 原版发现

- `sfb implements s7d,ml4,cz4` = MutableSharedFlow
  （v7d 委托）。
- **`ml4` = SharedFlow 接口**（修正 1019 的
  "会话状态 iface" 误判）。
- `em8 extends bwc implements cm8` = Mutex
  （owner$volatile CAS）；`fm8` = 工厂+NO_OWNER。
- 全代码库普及（nr1/vmc/vs4/b50）。

## Harmony 决策

Flow→@Observed/EventEmitter；Mutex→async lock。

## 产出

- 证据：`phase-1035-coroutine-primitives.md`
- Fixture：`d02-coroutine-primitives.mjs`（10/10）
- ADR-0979；全量 Replay 见本提交。
