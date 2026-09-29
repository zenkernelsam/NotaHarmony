# ADR-0937 — `z5c.x` apply 侧载荷分派

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `z5c.x` = 32-case 序数→载荷类全表（l2d..ud8），
  与 `zq9.a` 反向表严格对偶；`new T()`→`uq9.q(holder)`
  初始化→返回。
- ordinal 0（NONE）= fail-loud（`rgc.b`+throw）。
- `uq9.q`=payload@vtable14(f5)，`r`=transient@16(f6)；
  toString 实证字段名序。
- `aq1` = ClientOp 行 {uq9?,qo5,length}——超 cap 行
  blob 置 null 但保留 opId+length。
- `gk4.m`=qo5 解包；`gk4.o`=8B-long→qo5 列表解码。

## Harmony 决策

等价：分派表全对应 + NONE fail-loud + 行三段语义。

## Parity 状态

等价。

## 验证

- `d02-apply-dispatcher.mjs`：39/39 通过。
