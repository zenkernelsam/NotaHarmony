# ADR-1108：core/network 网络层

## 状态

已接受（Phase 1164）。

## 决策

- 异常分类：`HttpStatusException{code,×3}`、
  `NoConnectivityException`、`NotAuthenticatedException`
  （包私有）—— 同步网关 3 语义失败。
- `a` = 带 auth+连通性门控的 suspend 请求
  （`invokeSuspend throws` 双异常）。

## 依据

`extends IOException` ×3 + `a extends n8e implements wx4`
+ throws 声明。

## 后果

Harmony：`@ohos.net.http` 对应异常（HTTP 码/连通性/
认证）；async + 前置门控。
