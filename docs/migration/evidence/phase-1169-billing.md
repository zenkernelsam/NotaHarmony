# Phase 1169 证据 — billing 层（Play + Samsung 双后端 + domain 订阅）

来源：`data/billing/gateway/` + `data/samsungbilling/gateway/` +
`domain/subscription/`（12 文件，全异常分类）。

## `data/billing/gateway/` ×5 — Google Play Billing 异常

```java
MissingOverviewAfterGrantException   // grant 后无 overview
PlayPurchaseAlreadyClaimedException  // 已领取
PlayPurchaseRejectedException        // 已拒
PlayValidationUnavailableException   // 校验不可用
PostGrantOverviewRefreshException    // grant 后刷新失败
```

## `data/samsungbilling/gateway/` ×4 — Samsung IAP 并行异常

```java
MissingSamsungOverviewAfterGrantException
SamsungPurchaseAlreadyClaimedException
SamsungPurchaseInvalidException
SamsungValidationUnavailableException(Exception)
```

## `domain/subscription/` ×3 — domain 级

```java
PurchaseAcknowledgmentException   // 签收失败
RestoreIncompleteException        // 恢复不完整
SamsungIapDisabledException       // Samsung IAP 禁用
```

## 判定：双 IAP 后端，Android-store 专属

- **两个并行计费后端**：Google Play Billing + Samsung IAP
  （同一应用双渠道，按设备/商店路由）。
- 9 个 gateway 异常（Play 5 + Samsung 4，几乎对称：Grant/
  Claimed/Rejected|Invalid/Unavailable/Refresh）。
- 3 个 domain 异常（签收/恢复/Samsung-禁用）。
- 全 `IllegalStateException`/`RuntimeException` 类。

## Harmony 决策 — **fail-closed**

Google Play Billing + Samsung IAP 均为 **Android 商店专属
SDK**，HarmonyOS 无对应 —— IAP Kit 是另一套：

- 订阅/购买流 → Harmony **IAP Kit**（`iap.createPurchase`
  等）重新适配 —— 非等价移植，需重写后端适配层。
- 12 异常语义保留为 Harmony 订阅域的错误分类参考
  （grant/claim/reject/validate/refresh/ack/restore 语义
  在 IAP Kit 流程中仍有对应）。
- 双渠道路由（Play vs Samsung）在 Harmony 不适用 —
  单 IAP Kit 后端。

## 产出

- fixture `d02-billing.mjs`（10 断言）。
- ADR-1113（fail-closed）；中文报告。
