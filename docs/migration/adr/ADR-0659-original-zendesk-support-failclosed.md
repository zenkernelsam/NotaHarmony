# ADR-0659 「Help/Support Center」Zendesk 帮助中心 fail-closed 登记

- 状态：Accepted
- 日期：2026-09-25
- 关联 Phase：711
- 接续：ADR-0652（私有后端 fail-closed 判据）、ADR-0658（
  SETTINGS_SUPPORT_DIAGNOSTICS 行已随尾项登记）
- 证据：`docs/migration/evidence/original-zendesk-support-jadx-2026-09-25.md`

## 背景

原版 `ui_support__*`（54 字符串）覆盖完整帮助/支持中心：

- FAQ 浏览器（`ui_support__faq_*`、分类 sections、文章搜索）
- "Contact Support" 工单表（issue 类型、subject/description、
  email、附件、隐私同意）→ "Send to Support"

实现层 `com.gingerlabs.notability.ui.support.data.a`（Retrofit）：

```java
@kz4("global/zendesk/v2/help_center/articles/search.json")  // FAQ 搜索
@oy9("global/zendesk/v2/requests.json")                    // 工单提交
@oy9("global/zendesk/v2/uploads.json")                     // 附件上传
```

全部路径经 Notability 私有后端 `global/zendesk/v2/*` 代理到
Zendesk——与 Learn/YouTube 同族的私有 API 依赖。

## 决定

1. **不实现帮助/支持中心**，登记结构性 fail-closed：FAQ 内容与
   工单提交均需 Notability 私有 Zendesk 代理，Harmony 无该
   后端。
2. **Harmony 无 Help/Contact Support 入口**：等价于
   `SETTINGS_SUPPORT_DIAGNOSTICS`（`ac4.U0`）旗标关闭态
   （ADR-0658 已登记该设置行）。
3. `ui_support__*` 字符串不进入 Harmony 资源。

## 后果

- 旗标关闭的原版体验（无支持行/无帮助中心）= Harmony 体验；
- 若未来有自托管 FAQ/反馈通道需求，应新建独立设计而非移植
  Zendesk 路径。
