# ADR-0786 — 计费/订阅失败分类学归档

- 状态：已接受（整链 fail-closed）
- 证据：`docs/migration/evidence/phase-842-billing-taxonomy.md`
- 回放：`docs/migration/replays/d02-billing-taxonomy.mjs`（13/13）

## 决定

1. 计费异常面归档：Play 渠道 6 类 + Samsung 渠道 5 类 +
   `SerializationException`（购买凭据）——类型化恢复信号。
2. **整条变现面 fail-closed**：GMS Billing / Galaxy IAP 均无
   Harmony 等价物，项目不实现付费层；paywall/upsell 字符串
   面（FinishNotes、版本历史两闸）登记不移植。
3. Harmony settings 无订阅行断言固化于 Replay。

## 后果

`data/billing`/`data/samsungbilling`/`data/subscription`/
`domain/subscription` 四包闭合；monetization 面完整登记。
