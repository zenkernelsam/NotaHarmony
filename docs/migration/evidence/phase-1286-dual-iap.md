# Phase 1286 证据 — 双 IAP 计费 + 订阅域

来源：`data/{billing,samsungbilling}/` + `domain/
subscription/`。

## Play Billing

```
client/PlayBillingClient$BillingException   // Play Billing 客户端
gateway/MissingOverviewAfterGrantException  // 授权后无概览
gateway/PlayPurchaseAlreadyClaimedException // token 已认领
gateway/PlayPurchaseRejectedException       // "Play purchase
                                            //  token was not
                                            //  validated"（服务端校验失败）
gateway/PlayValidationUnavailableException  // 校验服务不可用
gateway/PostGrantOverviewRefreshException   // 授权后刷新
```

## Samsung IAP

`SamsungBillingClient$SamsungBillingException` +
gateway（MissingSamsungOverviewAfterGrant/SamsungPurchase
AlreadyClaimed/SamsungPurchaseInvalid/SamsungValidation
Unavailable）—— 与 Play 镜像的 Samsung 计费。

## domain/subscription

`PurchaseAcknowledgmentException`（确认失败）/
`RestoreIncompleteException`("Restore found active
purchases but none could be processed" 恢复不完整)/
`SamsungIapDisabledException`（Samsung IAP 禁用）。

## 语义

**双 IAP + 服务端校验网关** —— 客户端计费（Play/
Samsung）→ 购买 token 提交服务端 gateway 校验 →
授予订阅概览（entitlement）；异常分类法覆盖 token
无效/已认领/校验不可用/概览刷新/确认/恢复 ——
订阅制变现。

## Harmony 决策

Play/Samsung IAP → Harmony `iap`（华为应用内支付 kit）
统一客户端+保留服务端校验 gateway —— 双 IAP →
单 IAP+同网关协议；计费平台语义映射，校验保真。

## 产出

- fixture `d02-dual-iap.mjs`（10 断言）。
- ADR-1230；中文报告。
