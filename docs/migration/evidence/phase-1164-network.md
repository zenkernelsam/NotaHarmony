# Phase 1164 证据 — core/network 异常分类 + suspend 调用

来源：`core/network/` 命名类。

## 异常分类（extends IOException）

```java
HttpStatusException{int code, String×3}   // HTTP 错误
NoConnectivityException                   // 无网
NotAuthenticatedException (包私有)         // 未认证
```

## `a extends n8e implements wx4` = suspend HTTP 调用

```java
{bool I; int J;
 pcd K; String L; mcd M; bool N; long O,P}   // 捕获
invokeSuspend() throws NotAuthenticated,
                       NoConnectivity
```

`n8e` = Kotlin `SuspendLambda` 基；`wx4` = Function2。
封装一次带 auth+连通性检查的 HTTP/同步请求（`pcd`/
`mcd` = 请求/客户端型）—— 失败即抛两类 IOException。

## 语义

- 异常分类 = 同步网关的 3 语义失败（HTTP 态/无网/
  未认证）。
- `a` = 带 auth+连通性门控的 suspend 请求包装 —
  `invokeSuspend` 声明两 throws 即其检查。

## Harmony 决策

- 网络异常语义保（HTTP 码/连通性/认证 —— Harmony
  `@ohos.net.http` 对应）。
- suspend 请求 = async + auth/connectivity 前置检查。

## 产出

- fixture `d02-network.mjs`（10 断言）。
- ADR-1108；中文报告。
