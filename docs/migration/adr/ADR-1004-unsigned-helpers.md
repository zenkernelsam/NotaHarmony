# ADR-1004 — Kotlin 无符号值类族与助手层

## 状态

accepted（文档+fixture，无源改动）——**语义修正**

## 原版契约（`decompiled_1.0.3` 实证）

- `cmf`=UByte、`ymf`/`led`=UShort、`mmf`=UInt、
  `tmf`=ULong——**混淆名掩盖了无符号语义**。
- 波及：serverTime/audioTime/zIndex/schemaVersion/
  unicodeScalar/bits 哈希均为无符号；`exc.A0` 的
  `m&0xffff` 即是 UShort 比较。
- `njj.j0`=ULong.toString(radix)（负值高部拆分）；
  `rgc.b`=数据丢失 fail-loud IllegalStateException；
  `o14`=Kotlin intrinsics throw 簇；`ba6`=equals/compare。

## Harmony 决策

**全部相关字段按无符号建模**（BigInt/`>>>0`/`&mask`）；
此前若按有符号解读须在实现层修正。fail-loud 保留。

## Parity 状态

等价（ArkTS 无原生无符号——用掩码/BigInt）。

## 验证

- `d02-unsigned-helpers.mjs`：12/12 通过。
