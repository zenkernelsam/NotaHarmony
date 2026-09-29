# ADR-0984 — ID 类型分类

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `ttf` = UUID `{long I=msb, J=lsb}` + 零哨兵 +
  canonical 8-4-4-4-12 toString（`xag.c` hex）。
- `xwd` = FlatBuffer struct/table 基类
  `{I offset, J ByteBuffer, b(i,bb)}`。
- `utf`/`qo5 extends xwd implements ka4`——
  `qo5` = OpId{site:short, logicalTime:int}。
- `ka4` = `{a()→String}` 验证 iface（977）。

## Harmony 决策

`ttf`→{msb,lsb}/UUID 字符串；`qo5` OpId→同构 struct；
`xwd`→BufferView 等价。

## Parity 状态

等价。

## 验证

- `d02-id-types.mjs`：10/10 通过。
