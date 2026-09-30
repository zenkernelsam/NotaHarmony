# ADR-1221：protobuf-lite + Apollo 双层

## 状态

已接受（Phase 1277）。

## 决策

protobuf-lite `z7h`/`x7h` → Harmony `protobuf` 移植/手写
wire；Apollo 异常 → GraphQL 客户端错误类型。

## 理由

`z7h`=GeneratedMessageLite（parseFrom/mergeFrom/
dynamicMethod/zzaeh）；`x7h`=Builder Cloneable；
`ibj`/`fbj`=具体消息 —— 本地二进制层；Apollo
`ApolloException` sealed 分类法+normalized-sql 缓存 —
— GraphQL 网络层。

## 后果

Harmony 双层 = protobuf wire+GraphQL 错误类型 ——
本地+网络序列化语义保真。
