# ADR-1217：Apollo GraphQL 客户端

## 状态

已接受（Phase 1273）—— **fail-closed**。

## 决策

Apollo GraphQL → Harmony `rcp`/`http` 手写 GraphQL POST
（`{query,variables}` JSON）+`@defer` multipart 解析；
同步协议保持 GraphQL 语义。

## 理由

`gv`=GraphQL 拦截器（`graphql-response+json`+`deferSpec`
Accept）；`o20`=操作（INSERT/UPDATE/DELETE+变量）；
`p13`=multipart body；`ibj`/`z7h`=Client；`l7b`=
FetchPolicy —— Apollo GraphQL Kotlin；Harmony 无官方
Apollo 移植 —— fail-closed 到轻量 HTTP+JSON。

## 后果

Harmony 同步 = rcp/http GraphQL POST —— 协议语义保真，
客户端库重构。
