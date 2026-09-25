# Phase 714：原版登录+付费墙面 fail-closed 登记

字符串族审计收官：`feature_login__*`（55 串）与 `feature_paywall__*`
（101 串）——原版账号体系与订阅购买 UI 全家，此前仅依赖面登记
（ADR-0658 NOTE_LIMIT/订阅时长旗标、ADR-0661 六个月促销弹窗），
根面未正式登记。

## 原版证据链

- `nq7.java`：欢迎/登录屏——`welcome_to_notability` + 三张贴纸
  （`sticker_grow/momentum/everyone`）利益轮播；Apple/Google/
  Microsoft/邮箱四种登录（`continue_with_*`、`enter_password`、
  `a_link_has_been_sent_to_your_email_address`）；凭据流
  `png`/`rbd`/`vq7`/`zl2`/`v60`/`umh`。
- `hye.java`：付费墙 UI——`current_plan`、`badge_most_popular/
  most_powerful`、`classic_feature_1..6`、折扣脚注。
- `bba.java`：购买/恢复错误映射（`error_purchase_*` ×7、
  `error_restore_incomplete`、`samsung_already_claimed`）。
- 计费后端：`data.billing.client.PlayBillingClient`（Google Play
  Billing，`com.android.billingclient` 树）+ `data.samsungbilling.
  client.SamsungBillingClient`（Galaxy Store）+ 私有收据校验网关
  （`PlayValidationUnavailable/AlreadyClaimed/Rejected/
  MissingOverviewAfterGrant` 异常族）。

## 决定

结构性 fail-closed（`ADR-0662`）：Harmony 无 Play/Samsung 计费
客户端、无 OAuth 身份提供方、无 Notability 账号后端——应用为
单机本地笔记，不移植登录屏、付费墙、购买/恢复流程；156 条
字符串不进入资源。缺席即忠实边界。

## 验证

- `d05-original-login-paywall-fail-closed.mjs`（330 断言：登录面
  字符串×10/nq7 站点/付费墙字符串×10/hye+bba 站点/五计费类
  文件存在性/billingclient 树/全部 ets 文件无登录付费墙实现/
  字符串缺席/ADR+证据）。
- 全套件重跑、双 HAP 构建通过后记录于修复总纲。
