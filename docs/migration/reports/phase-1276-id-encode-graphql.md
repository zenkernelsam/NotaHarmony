# Phase 1276 报告 — 打包ID+实体解码+GraphQL操作

## 完成内容

- `mmf`=无符号 int value-class（`i&0xFFFFFFFF` 打包）；
  `njj.A(cee)→qo5`=FlatBuffers 实体-id 解码器 + `j0`=
  radix-toString + Modifier 助手；`ft9`=GraphQL
  Operation iface（id/name/document）；`tr2`=Apollo
  CustomScalarAdapters —— 实体寻址+同步协议桥。

## 产出

- evidence `phase-1276-id-encode-graphql.md`
- fixture `d02-id-encode-graphql.mjs`（10/10）
- ADR-1220
