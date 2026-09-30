# Phase 1277 报告 — protobuf-lite + Apollo 双层

## 完成内容

- **protobuf-lite**：`z6h`=MessageLite（a→byte[]+b(i9h)）、
  `x7h`=Builder（Cloneable+mergeFrom）、`z7h`=
  GeneratedMessageLite（parseFrom+dynamicMethod+zzaeh）、
  `ibj`/`fbj`=消息+builder —— 本地二进制层；
- **Apollo**：`ApolloException` sealed 分类法（GraphQL/
  Http/Network/WebSocket/CacheMiss/JsonData/NoData/…）+
  normalized-sql 缓存 —— 网络/同步层。

## 产出

- evidence `phase-1277-proto-apollo.md`
- fixture `d02-proto-apollo.mjs`（10/10）
- ADR-1221
