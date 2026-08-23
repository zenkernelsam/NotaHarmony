# ADR-0286: Bind Photo Feedback To The Originating Page

日期：2026-08-23（Asia/Shanghai）
状态：Accepted

## Context

Phase 305/307 已把图片插入失败状态和成功清除绑定到发起页，但照片入口的 partial-failure 与 whole-batch failure
toast 仍是无页面上下文的全局副作用。异步 picker、ingress 和多图持久化期间切页后，旧页反馈会显示在新页。

## Decision

进入 `startOriginalPhotoInsert()` 时捕获 generation/pageId。部分失败 toast 只在发起页上下文匹配且存在严格前缀时
显示；整批失败 toast 也只在同页显示。跨页失败保留 hilog 并释放 busy；数据库、Undo history 和 outcome 契约不变。
