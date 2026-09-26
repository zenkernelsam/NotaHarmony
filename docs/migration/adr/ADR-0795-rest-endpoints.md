# ADR-0795 — REST 端点注册表封存

- 状态：已接受（整链 fail-closed）
- 证据：`docs/migration/evidence/phase-851-rest-endpoints.md`
- 回放：`docs/migration/replays/d02-rest-endpoints.mjs`（10/10）

## 决定

1. 原版 REST 面完整封存：**24 端点**——auth×7（nonce、
   google/microsoft sign-in、passkey register/authenticate
   options+verify）、Stripe×2、email×1、images×1、
   collab-api×3、learn×3、Intercom×3、Zendesk×4。
2. **双帮助台后端并存**（Intercom `global/intercom/v1` +
   Zendesk `global/zendesk/v2`）登记为版本过渡痕迹。
3. 全部端点 fail-closed（后端依赖）；auth 契约与 843
   OAuth 活动、771 passkey 面交叉印证。
4. Harmony 无 HTTP 客户端面断言固化于 Replay。

## 后果

网络面完备闭合：socket 双通道（849/850）+ REST 24 端点 +
后端环境枚举（805）构成完整外部服务边界。
