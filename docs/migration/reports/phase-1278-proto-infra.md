# Phase 1278 报告 — protobuf-lite 基础设施

## 完成内容

- `h9h`=RawMessageInfo（`{z6h defaultInstance, String
  info, Object[] objects, int flags}` 免反射字段编码）；
  `g9h`=ProtobufArrayList（Object[]+扩容）;`s7h`=
  ExtensionRegistryLite；`i9h`=Schema iface —— protobuf-
  lite codegen 运行时（免反射序列化/解析）。

## 产出

- evidence `phase-1278-proto-infra.md`
- fixture `d02-proto-infra.mjs`（10/10）
- ADR-1222
