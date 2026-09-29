# Phase 1045 报告 — 文本 CRDT 操作载荷族

## 范围

`e46`/`f46`/`pub`/`qub`/`f2c` 五个文本操作载荷。纯审计。

## 原版发现

- 字段：InsertChar{location,unicodeScalar,textField}；
  InsertString{location,string@6 required,textField@8}；
  RemoveChar{location required,textField}；
  RemoveChars/ReviveChars{locations 向量 lv2.N/O,textField}。
- `textField:qo5` = 所属文本块锚点 opId。
- 校验：码点合法 / 非空串 / locations>0 / RemoveChar 恒过。
- required 缺失 `o14.i` fail-loud；`mmf.a` 标量格式化。

## Harmony 决策

布局/校验/文案逐条对齐。

## 产出

- 证据：`phase-1045-text-op-payloads.md`
- Fixture：`d02-text-op-payloads.mjs`（12/12）
- ADR-0989；全量 Replay 见本提交。
