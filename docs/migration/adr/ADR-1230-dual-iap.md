# ADR-1230：双 IAP 计费

## 状态

已接受（Phase 1286）。

## 决策

Play/Samsung IAP → Harmony `iap`（华为应用内支付）
统一客户端+保留服务端校验 gateway 协议。

## 理由

`data/billing`=Play Billing client+服务端校验 gateway
（token-not-validated/AlreadyClaimed/ValidationUnavailable
+Overview refresh）；`data/samsungbilling`=Samsung IAP
镜像；`domain/subscription`=Acknowledge/Restore/
ProviderDisabled —— 双 IAP+服务端 entitlement 校验。

## 后果

Harmony 计费 = iap kit 单客户端+同 gateway 协议 —
— 计费平台映射，校验语义保真。
