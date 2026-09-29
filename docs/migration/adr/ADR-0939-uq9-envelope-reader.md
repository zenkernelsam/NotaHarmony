# ADR-0939 — `uq9` Op 信封读侧访问器表

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- 七字段：f0 id(qo5,必需)/f1 clientTime/f2 serverTime/
  f3 audioTime(tmf)/f4 payloadType(byte→haa)/
  f5 payload/f6 transientInteraction(sdf)——
  vtable 槽 4/6/8/10/12/14/16。
- `m()` 越界 byte → haa[NONE] 界回退（两阶段：
  先 NONE 再 `z5c.x` fail-loud）。
- `uq9 implements ka4`；equals/hashCode 走 cee 缓冲等式。

## Harmony 决策

等价：访问器槽位 + NONE 界回退。

## Parity 状态

等价。

## 验证

- `d02-uq9-envelope-reader.mjs`：13/13 通过。
