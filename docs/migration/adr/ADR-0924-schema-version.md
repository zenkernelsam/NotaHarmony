# ADR-0924 — ar6 SchemaVersion 枚举全史 + rgc.a=15

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

`ar6` = SchemaVersion 枚举 0–15（PRE_SHIPPING→
INK_EFFECT），`K`=当前=**v15 INK_EFFECT**；
`rgc.a=ar6.K.I` 为读写共用常量源（q4j f7 写、
nce u16 版本闸读）。每版本=特性闸门（v2 layoutMode
… v15 inkEffect）。

## Harmony 决策

Harmony schemaVersion 写侧常量 = 15；读侧 u16 比较
已对齐；**特性版本门控语义存档**——各字段的
"最低版本"由此枚举对应。

## Parity 状态

等价。

## 验证

- `d02-schema-version.mjs`：22/22 通过。
