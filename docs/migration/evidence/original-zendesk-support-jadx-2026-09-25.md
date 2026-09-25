# 原版 Zendesk 帮助/支持中心 — JADX 证据（2026-09-25，Phase 711）

## 字符串面（54 条 `ui_support__*`）

- FAQ 浏览：`faqs_header`/`faq_general`/`faq_getting_started`/
  `faq_reported_issues`/`latest_updates_header`/`top_results`/
  `search_placeholder`/`search_min_length`/`no_results`/
  `visit_help_center`/`offline_message`
- 工单表：`tab_contact`/`issue_header`+9 类 issue
  （crashes/performance/data_loss/handwriting/missing_content/
  subjects/syncing/templates/text/other）、`subject_header`/
  `description_header`/`email_header`/`name_header`、
  `field_required`/`email_invalid`
- 提交：`submit`/`submitting`/`success_*`/`submit_another`、
  `disclaimer_prefix`（诊断信息同意）+ `privacy_policy`/
  `terms_and_conditions`
- 附件：`add_photo`/`remove_attachment`/`error_*`（附件读/
  上传/大小/数量/网络/通用）

## 后端面

`sources/com/gingerlabs/notability/ui/support/data/a.java`
（Retrofit interface）：

```java
@kz4("global/zendesk/v2/help_center/articles/search.json")
Object a(query, per_page)                       // FAQ 文章搜索
@kz4("global/zendesk/v2/help_center/articles/search.json")
Object b(section, per_page, sort_by, created_after)  // 分区列表
@oy9("global/zendesk/v2/requests.json")
Object c(h request)                             // 工单创建
@oy9("global/zendesk/v2/uploads.json")
Object d(filename, Content-Type, nwb file)      // 附件上传
```

- `ZendeskApiException`（同包）+ `b/c/d/e/f/g/h/i/j/k` DTO
  （`ZendeskArticlesResponse`/`ZendeskComment` 等）。
- 全部端点走 `global/zendesk/v2/*` ——Notability 后端代理到
  Zendesk，非直连 Zendesk 公共 API。

## UI 面

- `q31.java:332-355`：FAQ sections 渲染（`faqs_header` +
  `faq_general`/`faq_reported_issues`/`faq_getting_started`）。
- `gx1.java:52-55`：提交按钮态 `submitting`/`submit`。
- 入口行：`SETTINGS_SUPPORT_DIAGNOSTICS`（`ac4.U0`，
  `q0.java:51` `jeh.f`）——ADR-0658 已登记旗标关闭态。

## Harmony 侧核对

- `note/src` 无 support/faq/zendesk 实现与入口。
- `SETTINGS_SUPPORT_DIAGNOSTICS` 行已随 Phase 710 登记为
  旗标关闭态。

## 结论

帮助中心=私有 Zendesk 代理后端面；Harmony 呈现旗标关闭态，
按 ADR-0659 登记 fail-closed。
