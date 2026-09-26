# Phase 851 — Retrofit REST 端点注册表闭合

## 范围

全树 `@f16`(GET)/`@y9c`(POST) 注解扫描——10 接口 24 端点。

## 原版发现

### 端点按域

- **auth×7**（b2f）：nonce、google/microsoft sign-in、
  passkey register/authenticate options+verify——完整
  passkey REST 契约（与 771/843 印证）；
- **Stripe×2**（c1h）：customers/prices；
- **collab-api×3**（mkj/nhf）：note/create + index 上传下载；
- **learn×3**：awaitQuizJob、summary-content-stream（流式）、
  parseSyllabus；
- **Intercom×3** + **Zendesk×4**——双帮助台后端并存
  （版本过渡痕迹）；
- images/thumbnails + email/subscribe。

## Harmony 侧

无 REST 客户端面——全部后端依赖 fail-closed。

## 验证

- Replay `d02-rest-endpoints.mjs`：**10/10**（24 端点总数、
  域计数 7 项、方法类型、Harmony 零引用断言）。
- ADR-0795。**网络面完备闭合**（socket×2 + REST×24 +
  环境枚举 805）。
