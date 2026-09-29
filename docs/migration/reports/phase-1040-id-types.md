# Phase 1040 报告 — ID 类型分类

## 范围

`ttf`/`utf`/`qo5`/`xwd`/`ka4` ID 类型族。纯审计。

## 原版发现

- `ttf` = UUID `{long msb,lsb}` + 8-4-4-4-12 格式化
  （xag.c hex）+ 零哨兵。
- `xwd` = FlatBuffer struct 基类 `{I offset,
  J ByteBuffer}`；`utf`/`qo5 extends xwd`。
- `qo5` = OpId `{site:short, logicalTime:int}`。
- `ka4` = `{a()→String}` 验证 iface。

## Harmony 决策

UUID/OpId 同构保留；xwd→BufferView。

## 产出

- 证据：`phase-1040-id-types.md`
- Fixture：`d02-id-types.mjs`（10/10）
- ADR-0984；全量 Replay 见本提交。
