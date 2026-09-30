# ADR-1110：ui/fileimport + ui/support

## 状态

已接受（Phase 1166）。

## 决策

- 文件导入 = `PartialImportException(List,Throwable)`
  部分失败 —— Harmony 文件选择 + 同语义。
- 支持 = Zendesk REST API（suspend retrofit + DTO
  `{subject,comment,requester,viaId=48,ticketFormId}`）
  → `@ohos.net.http` 客户端 / fail-closed。

## 依据

`PartialImport(List,th)` + `a` suspend iface + `e` DTO
`viaId=48/ticketFormId=360000467551L` + `ZendeskApiException`。

## 后果

Harmony：导入部分失败同语义；Zendesk REST /
fail-closed（无 SDK 时隐藏入口）。
