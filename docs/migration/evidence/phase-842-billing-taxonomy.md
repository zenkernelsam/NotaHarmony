# Phase 842 — 计费/订阅失败分类学闭合

证据：`decompiled_1.4.2/sources/com/gingerlabs/notability/data/billing/`
+ `data/samsungbilling/` + `domain/subscription/` + `data/subscription/`

## 一、异常类型清单（10 类）

**Play 侧**：
- `PlayBillingClient$BillingException`——客户端层失败；
- `PlayPurchaseAlreadyClaimedException`——已领取；
- `PlayPurchaseRejectedException`——拒绝；
- `PlayValidationUnavailableException`——校验不可用；
- `PostGrantOverviewRefreshException`——授权后概览刷新失败；
- `MissingOverviewAfterGrantException`——授权后概览缺失。

（domain/subscription 宿主）：`PurchaseAcknowledgmentException`——
确认失败；`RestoreIncompleteException`——恢复不完整。

**Samsung 侧**（Galaxy Store 并行路径，839 已记 4 异常 + 本相位）：
- `SamsungIapDisabledException`——IAP 禁用；
- `SamsungBillingException`/`SamsungPurchaseAlreadyClaimed`/
  `SamsungPurchaseInvalid`/`SamsungValidationUnavailable`/
  `MissingSamsungOverviewAfterGrant`。

**通用**：`SerializationException`（购买凭据序列化）。

## 二、Paywall 字符串面

`feature_paywall__error_purchase_billing_unavailable` /
`note_limit_offer_cta_upgrade` / `restore_subscribed_elsewhere`；
settings 订阅行：`manage_subscription`/`user_tier_premium`/
`subscription_data_unavailable`/`subscription_load_failed`；
升级闸：`finish_notes_upgrade*` + `version_history_upsell_upgrade`
（FinishNotes 与版本历史为付费门禁面）。

## 三、Harmony 侧

**无订阅/付费墙实现**：settings 无订阅行，无 IAP 客户端，
无用户层级（tier）模型——整条变现面 fail-closed
（GMS Billing/Galaxy IAP 均无 Harmony 等价物，且项目选择
不实现付费层）。原版两闸点（FinishNotes、版本历史）登记。

## 四、结论

计费面闭合：10 类异常 + 2 并行渠道（Play/Samsung）+
paywall/upsell 字符串面全归因；Harmony 全链 fail-closed。
