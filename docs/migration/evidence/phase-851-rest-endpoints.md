# Phase 851 — Retrofit REST 端点注册表闭合

证据：`decompiled_1.4.2` 全树 `@f16`(GET)/`@y9c`(POST)
注解盘点——10 个接口 20 端点。

## 一、完整端点表

| 接口 | 方法 | 路径 | 域 |
|------|------|------|----|
| b2f | POST | /auth/nonce | 认证 |
| b2f | POST | /google/sign-in | 认证 |
| b2f | POST | /microsoft/sign-in | 认证 |
| b2f | POST | /passkey/register/options | 认证 |
| b2f | POST | /passkey/register/verify | 认证 |
| b2f | POST | /passkey/authenticate/options | 认证 |
| b2f | POST | /passkey/authenticate/verify | 认证 |
| c1h | POST | /stripeConsumer/customers | Stripe 计费 |
| c1h | POST | /stripeConsumer/prices | Stripe 计费 |
| dxa | POST | /email/subscribe | 邮件订阅 |
| nkj | POST | /images/thumbnails | 图片缩略图 |
| mkj | POST | collab-api/note/create | 协作 |
| nhf | GET | collab-api/note/{id}/index | 协作索引 |
| nhf | POST | collab-api/note/{id}/index/upload | 协作索引 |
| qq0 | GET | learn/awaitQuizJob/{quizJobId} | Learn 测验 |
| hch | GET | learn/summary-content-stream/{summaryId} | Learn 流式摘要 |
| vih | POST | learn/parseSyllabus | Learn 大纲 |
| nv7 | GET | global/intercom/v1/articles | **Intercom** 帮助 |
| nv7 | GET | global/intercom/v1/articles/search | Intercom 搜索 |
| nv7 | POST | global/intercom/v1/support-request | Intercom 工单 |

另：Zendesk `a` 接口 4 端点（843 已记）——**双帮助台
后端并存**（Intercom + Zendesk，版本过渡态）。

## 二、结构观察

- 全部 fail-closed：后端依赖，Harmony 无 HTTP 客户端面；
- `b2f` 7 端点构成完整 auth+passkey REST 契约（配合 843
  OAuth 活动与 771 passkey 面）；
- `collab-api` 与 socket 通道（849/850）构成完整同步面；
- Intercom/Zendesk 双支持后端为过渡痕迹。

## 三、结论

REST 层完整枚举闭合（20+4=24 端点）；全部归口 fail-closed
或已登记相位。
