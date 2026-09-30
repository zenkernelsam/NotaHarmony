# Phase 1286 报告 — 双 IAP 计费 + 订阅域

## 完成内容

- `data/billing`=Play Billing（client BillingException+
  gateway：MissingOverviewAfterGrant/AlreadyClaimed/
  Rejected"token not validated"/ValidationUnavailable/
  PostGrantOverviewRefresh）；`data/samsungbilling`=
  Samsung IAP 镜像；`domain/subscription`=
  PurchaseAcknowledgment/RestoreIncomplete("active
  purchases but none could be processed")/SamsungIap
  Disabled —— 双 IAP+服务端 entitlement 校验。

## 产出

- evidence `phase-1286-dual-iap.md`
- fixture `d02-dual-iap.mjs`（10/10）
- ADR-1230
