# Phase 1036 报告 — 续体/lambda 原语 + asd StateFlow

## 范围

`ff2`/`n8e`/`wx4`/`lr0`/`hy4` + `asd`/`o5`/`hl8`。
纯审计。

## 原版发现

- `ff2 extends lr0` = BaseContinuationImpl；
  `n8e extends ff2 implements hy4` = SuspendLambda；
  `wx4 extends xx4` = FunctionN lambda iface。
- **`asd extends o5 implements hl8,ml4,cz4` =
  MutableStateFlow**——`_state$volatile` ARFU +
  `int M` 序号；StateFlow⊂SharedFlow。

## Harmony 决策

StateFlow→@State/@Observed；suspend→async。

## 产出

- 证据：`phase-1036-stateflow-lambdas.md`
- Fixture：`d02-stateflow-lambdas.mjs`（10/10）
- ADR-0980；全量 Replay 见本提交。
