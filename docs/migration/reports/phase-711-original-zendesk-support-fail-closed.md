# Phase 711：原版 Zendesk 帮助/支持中心 fail-closed 登记

字符串族审计：`ui_support__*`（54 条）为完整帮助/支持中心
（FAQ 浏览 + "Contact Support" 工单表），未登记。

## 原版证据链

- `com.gingerlabs.notability.ui.support.data.a`（Retrofit）：
  `global/zendesk/v2/help_center/articles/search.json`（FAQ
  搜索/分区列表）、`global/zendesk/v2/requests.json`（工单
  创建）、`global/zendesk/v2/uploads.json`（附件上传）——
  全部经 Notability 私有后端代理到 Zendesk。
- `q31.java`：FAQ sections 渲染；`gx1`：提交按钮态。
- 入口行：`ac4.U0` SETTINGS_SUPPORT_DIAGNOSTICS 门控
  （`q0:51` `jeh.f`）——Phase 710 尾项已登记旗标关闭态。

## 决定

- 私有 Zendesk 代理后端 → 结构性 fail-closed（`ADR-0659`），
  与 Learn/YouTube/Klipy 同族判据。
- Harmony 无 Help/Contact Support 入口，`ui_support__*`
  字符串不进入资源——等价旗标关闭态。

## 验证

- `d05-original-zendesk-support-fail-closed.mjs`（325 断言：
  字符串面/三端点/入口门控/全部 ets 文件无 Zendesk 实现/
  ADR+证据）。
- 全套件重跑、双 HAP 构建通过后记录于修复总纲。
