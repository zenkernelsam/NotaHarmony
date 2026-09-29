# ADR-0980 — 续体/lambda 原语 + asd StateFlow

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `ff2 extends lr0` = BaseContinuationImpl；
  `n8e extends ff2 implements hy4` = SuspendLambda
  （arity）；`wx4 extends xx4` = FunctionN。
- **`asd extends o5 implements hl8,ml4,cz4` =
  MutableStateFlow**——`_state$volatile` ARFU +
  `int M` 序号+初值 ctor。

## Harmony 决策

`asd` StateFlow→@State/@Observed（响应式状态）；
suspend/lambda→async+函数类型。

## Parity 状态

语义等价。

## 验证

- `d02-stateflow-lambdas.mjs`：10/10 通过。
