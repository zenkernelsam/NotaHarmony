# ADR-0982 — ze9 bundle 头 + a79 常量

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `ze9 implements ye9` = bundle 头
  `{ttf a,b,d,f + short c(schemaVersion) + long e}` —
  六字段记录。
- `a79` = 常量注册表（er6 L/qed N/float P/w69 R +
  协程 helpers）。
- `m09.a` 物化器构造 ze9（r4j.b/c+r29.l/j/k/m）。

## Harmony 决策

ze9 头模型保留；a79 注册表移植。

## Parity 状态

等价。

## 验证

- `d02-ze9-header.mjs`：10/10 通过。
