# ADR-1222：protobuf-lite codegen 基础设施

## 状态

已接受（Phase 1278）。

## 决策

`h9h`/`g9h`/`s7h`/`i9h` protobuf-lite 内部 → Harmony
手写 wire+字段表/protobuf-ts。

## 理由

`h9h`=RawMessageInfo（生成字段布局 String+Object[]
免反射描述符）；`g9h`=ProtobufArrayList；`s7h`=
ExtensionRegistryLite；`i9h`=Schema —— protobuf-lite
codegen 运行时。

## 后果

Harmony protobuf = 手写 wire+字段描述符 —— codegen
语义保真。
