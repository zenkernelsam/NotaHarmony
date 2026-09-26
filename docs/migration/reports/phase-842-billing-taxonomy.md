# Phase 842 — 计费/订阅失败分类学

## 范围

`data/billing` + `data/samsungbilling` + `domain/subscription` +
`data/subscription` 异常面审计。

## 原版发现

### 双渠道异常分类学

**Play**：BillingException / PurchaseRejected /
PurchaseAlreadyClaimed / ValidationUnavailable +
domain 侧 PurchaseAcknowledgment / RestoreIncomplete /
PostGrantOverviewRefresh / MissingOverviewAfterGrant。

**Samsung（Galaxy Store 并行）**：SamsungBillingException /
SamsungPurchaseAlreadyClaimed / SamsungPurchaseInvalid /
SamsungValidationUnavailable / MissingSamsungOverviewAfterGrant
+ SamsungIapDisabled。

通用：`SerializationException`（购买凭据序列化）。

### Paywall 字符串面

`feature_paywall__*`、`manage_subscription`、`user_tier_premium`、
`subscription_load_failed` + 两付费闸：`finish_notes_upgrade*`
与 `version_history_upsell_upgrade`。

## Harmony 侧

**无订阅/付费墙实现**：无 IAP 客户端、无 tier 模型、settings
无订阅行——整条变现面 fail-closed（GMS/Galaxy IAP 不可移植）。

## 验证

- 新 Replay `d02-billing-taxonomy.mjs`：**13/13**（异常目录
  计数、Play/Samsung 关键类、paywall/upsell 断言、Harmony
  无订阅断言）。
- ADR-0786。**计费面闭合。**
