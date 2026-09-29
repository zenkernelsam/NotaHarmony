# ADR-0983 — ze9 访问器→字段映射 + led

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `ze9` 访问器：c()→a(noteId)、a()→e(timestamp)、
  b()→d、d()→led(c)=**schemaVersion 装箱**、
  e()→f。
- `led` = short value-class `{short a}`+
  `a(short)→String` toString——schemaVersion 装箱。

## Harmony 决策

ze9 记录保留；led→`SchemaVersion` 类型包装。

## Parity 状态

等价。

## 验证

- `d02-ze9-accessors.mjs`：10/10 通过。
