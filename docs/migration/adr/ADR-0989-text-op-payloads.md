# ADR-0989 — 文本 CRDT 操作载荷字段布局

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- InsertChar `{location:cxc, unicodeScalar:int, textField:qo5}`；
  InsertString `{location, string@6 required, textField}`；
  RemoveChar `{location required, textField}`；
  RemoveChars/ReviveChars `{locations:cxc[] 向量, textField}`。
- 校验：合法码点 / 非空串 / locations>0 / RemoveChar 无校验。
- required 缺失 → `o14.i` fail-loud。

## Harmony 决策

字段布局+required+校验文案逐条保留；码点判定用等价 API。

## Parity 状态

等价。

## 验证

- `d02-text-op-payloads.mjs`：12/12 通过。
