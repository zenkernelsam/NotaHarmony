# Phase 1164 报告 — core/network

## 完成内容

- 网络异常分类（HttpStatus/NoConnectivity/NotAuthenticated）
  + `a` suspend HTTP 调用（auth+连通性门控，
  `invokeSuspend throws` 双异常）。

## 产出

- evidence `phase-1164-network.md`
- fixture `d02-network.mjs`（10/10）
- ADR-1108
