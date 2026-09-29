# Phase 1038 报告 — ze9 bundle 头 + a79 常量

## 范围

`ze9`/`ye9` 头模型 + `a79`/`r4j` 常量/访问器。
纯审计。

## 原版发现

- `ze9 implements ye9` = bundle 头
  `{ttf×4 + short schemaVersion + long}` 六字段。
- `a79` = 常量注册表（er6/qed/float/w69 + 协程）。
- `m09.a` 构造 ze9（r4j.b/c + r29.l/j/k/m 头字段）。

## Harmony 决策

头模型+常量注册表保留。

## 产出

- 证据：`phase-1038-ze9-header.md`
- Fixture：`d02-ze9-header.mjs`（10/10）
- ADR-0982；全量 Replay 见本提交。
