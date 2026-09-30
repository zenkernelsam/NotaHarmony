# Phase 1166 证据 — ui/fileimport + ui/support Zendesk

来源：`ui/` 命名类。

## `ui/fileimport/data/importer/` = 文件导入

`PartialImportException(List, Throwable)` = 部分导入失败
—— `.note`/PDF 导入器：部分页/资产失败时返可恢复
列表 + 底层错。

## `ui/support/data/` = Zendesk 支持工单 API

```java
interface a {                          // retrofit API iface
  suspend d(filename,contentType,file)→k      // 上传附件
  suspend c(h request)→i                       // 建工单
  suspend b(apiKey,perPage)→b                  // 列表
  suspend b(sectionId,sortBy,createdAfter)     // 分区
}
b/c/e/f/h/i/k = Zendesk DTO（data class）：
  b{results:List}, c{body,uploads},
  e{subject,comment,requester,fields,viaId:I=48,
    ticketFormId:J=360000467551L}, ZendeskApiException
  （e 是真 Zendesk 工单 DTO —— viaId=48 / formId 默认）
```

Retrofit suspend 调用 + Kotlinx-serialized DTO —— Zendesk
支持工单后端。

## 语义

- 文件导入 = 部分失败语义（`PartialImport(List,th)`）。
- 支持 = Zendesk REST API（附件上传/建单/列表/分区）
  + 数据类 DTO + `ZendeskApiException`。
- 后端依赖 → fail-closed / 隐藏入口。

## Harmony 决策

- 导入器 → Harmony 文件选择 + 部分失败同语义。
- Zendesk → `@ohos.net.http` REST 客户端 / fail-closed
  （无 Zendesk SDK）。

## 产出

- fixture `d02-ui.mjs`（10 断言）。
- ADR-1110；中文报告。
