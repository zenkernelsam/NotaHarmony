# ADR-1113：billing（Play+Samsung 双 IAP 后端）— fail-closed

## 状态

已接受（Phase 1169）。

## 决策

Google Play Billing + Samsung IAP **双 Android 商店后端**
—— HarmonyOS 无对应 SDK → **fail-closed**：订阅/购买
用 Harmony **IAP Kit** 重写适配（非等价移植）；12 异常
语义保留为错误分类参考；双渠道路由不适用（单 IAP Kit）。

## 理由

`data/billing/gateway`（Play×5）+`data/samsungbilling/gateway`
（Samsung×4）并行对称异常 + `domain/subscription`×3 —
全是商店 SDK 流程的产物（grant/claim/reject/validate/
refresh/ack/restore）。

## 后果

Harmony：IAP Kit 后端适配层重写订阅流；异常分类沿用
Play/Samsung 的语义骨架（grant-after/claimed/rejected/
unavailable/refresh/ack/restore-incomplete）；无 Samsung
渠道。
