# Phase 1273 证据 — gv/o20/p13/ibj/l7b Apollo GraphQL 客户端

来源：`defpackage/{gv,o20,ml4,p13,ibj,l7b,cx8,mj8,nl5,
z7h,x7h,fbj}.java` + `com/apollographql/*`（20 文件）。

## `gv implements cx8` = GraphQL 拦截器

```java
ml4 a(o20 op) {
    // Accept: multipart/mixed;deferSpec=20220824,
    //   application/graphql-response+json, application/json
}
```

→ **Apollo GraphQL HTTP 拦截器** —— `@defer` 增量交付
+ `graphql-response+json` 协议。

## `o20 implements mj8` = GraphQL 操作记录

`{INSERT/UPDATE/DELETE}` + `Serializable` 变量字段 —
— Mutation/Query/Subscription 操作（`mj8`=Operation
iface）。

## `p13 implements nl5` = GraphQL 请求体

`{xfb/clock}` + `getContentType()/getContentLength()` —
— `nl5`=RequestBody（multipart 上传体）。

## `ibj extends z7h` = Apollo Client/Operation 基类

`fbj.y()/z()` 构建器 + `A/B/C/D` setter + `r(i)`/
`s()` —— `z7h`/`x7h`/`fbj` = Apollo 生成代码基类
（operation adapter/response）。

## `l7b` = FetchPolicy 枚举

`{int b,c}` + toString —— CacheFirst/NetworkFirst/
CacheOnly/NetworkOnly 策略。

## 语义

**Apollo GraphQL Kotlin** 客户端 —— 操作+multipart
body+`@defer` 增量响应+缓存策略 —— App 云同步/后端
协议层（GraphQL over HTTP，非 REST）。

## Harmony 决策

Apollo GraphQL → Harmony 无官方移植 —— 用 `rcp`/`http`
手写 GraphQL POST（`{query,variables}` JSON）+ `@defer`
multipart 解析 —— fail-closed：同步协议保持 GraphQL
语义，客户端库用轻量 HTTP+JSON 重构。

## 产出

- fixture `d02-graphql.mjs`（10 断言）。
- ADR-1217（fail-closed）；中文报告。
