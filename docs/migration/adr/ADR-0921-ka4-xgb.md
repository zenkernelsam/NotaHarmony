# ADR-0921 — ka4 校验契约 + xgb Realtime + x09 定性

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `ka4` = `{String a()}` 校验错误契约——全部注册类型
  实现，`ybg.c` 消费（a()→日志→ValidationException）。
- `xgb` = `Realtime{value:ulong}`——`compareUnsigned`
  无符号比较，`zq9.a` op 工厂第 4 参（realtime 时标）。
- `x09` = 文档模型接口（218 处引用），非线型。

## Harmony 决策

- ka4 契约 → Harmony 校验前置（fail-closed 一致）。
- Realtime → u64。

## Parity 状态

等价。

## 验证

- `d02-ka4-xgb.mjs`：8/8 通过。
