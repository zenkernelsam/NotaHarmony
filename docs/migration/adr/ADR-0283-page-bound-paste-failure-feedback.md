# ADR-0283: Bind Paste Failure Feedback To The Inserting Page

日期：2026-08-23（Asia/Shanghai）
状态：Accepted

## Context

Phase 304 阻止了授权后跨页继续读取和持久化，但失败反馈仍是无页面上下文的全局副作用。异步插入或规范化失败时，
用户可能已经切换页面；旧 catch 会调用 `reportSaveFailure()`，把新页置为 `saveFailed` 并显示旧页粘贴失败 toast。

## Decision

`insertOriginalPhotos()` 的保存失败反馈只在捕获页 generation/pageId/currentPage 三者仍匹配时写入；
剪贴板粘贴的 localized failure toast 也只在发起页上下文不变时显示。跨页失败保留 hilog 与 busy/history 释放，
但不污染当前页面状态。成功路径、部分插入前缀语义、权限门禁和完成缓存重同步不变。
