# Phase 1060 报告 — 无符号值类族与助手层

## 范围

`cmf`/`ymf`/`led`/`mmf`/`tmf` 无符号族、`njj`/`ba6`/
`rgc`/`o14`/`fa2`/`od4`/`vh2` 助手层。纯审计+语义修正。

## 原版发现

- **混淆名=Kotlin 无符号值类**：cmf=UByte( &255)、
  ymf/led=UShort( &65535)、mmf=UInt( &0xFFFFFFFF+
  `^MIN_VALUE` 比较)、tmf=ULong(njj.j0 无符号 fmt)。
- 语义修正：时间戳/序数/schemaVersion/unicodeScalar/
  哈希 bits 都是无符号——有符号解读会产生负值 bug。
- `njj.j0` = ULong.toString(radix) 高位拆分实现。
- `rgc.b` = "will lead to data loss when written to disk"
  fail-loud；`o14` = intrinsics throwers。

## Harmony 决策

无符号语义用掩码/BigInt 保留；fail-loud 文案保留。

## 产出

- 证据：`phase-1060-unsigned-helpers.md`
- Fixture：`d02-unsigned-helpers.mjs`（12/12）
- ADR-1004；全量 Replay 见本提交。
