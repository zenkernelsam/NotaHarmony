# Phase 1277 证据 — z6h/x7h/z7h 序列化双层 + Apollo 异常

来源：`defpackage/{z6h,x7h,z7h,fbj,ibj,s7h,i9h}.java`
+ `com/apollographql/apollo/exception/*`。

## 层 1 — protobuf-lite 生成基类

```java
z6h { a()→byte[]; abstract int b(i9h); }   // MessageLite
x7h implements Cloneable { z7h I/J;         // Builder
    c(byte[], s7h) mergeFrom; d(byte[]); }
z7h { c(z7h,byte[],s7h) parseFrom;          // GeneratedMessageLite
      o(Method,z7h,Object[]) dynamicMethod;
      zzaeh = InvalidProtocolBufferException }
ibj extends z7h;  fbj extends x7h           // 具体消息+builder
```

→ `ibj`/`fbj` 是 **protobuf 消息/构建器**（非 Apollo）—
— 本地二进制序列化层。

## 层 2 — Apollo 异常分类法

`com/apollographql/apollo/exception/`：
`ApolloException`(sealed RuntimeException) →
`ApolloGraphQLException`/`ApolloHttpException`/
`ApolloNetworkException`/`ApolloWebSocketClosedException`/
`CacheMissException`/`JsonDataException`/`NoDataException`/
`NullOrMissingField`/`SubscriptionOperationException` +
`apollo/cache/normalized/sql/ApolloInitializer`（SQL 缓存）。

## 语义

**双序列化层**：
- protobuf-lite = 本地/二进制消息（`z7h`/`x7h` codegen）；
- Apollo = GraphQL 网络/同步（拦截器+normalized SQL
  缓存+sealed 异常分类法）。

## Harmony 决策

protobuf-lite → Harmony `protobuf` 移植/手写 wire 格式；
Apollo 异常 → GraphQL 客户端错误类型 —— 双层语义保真。

## 产出

- fixture `d02-proto-apollo.mjs`（10 断言）。
- ADR-1221；中文报告。
