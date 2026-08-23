# ADR-0285: Bind Image Save Clear To The Inserting Page

日期：2026-08-23（Asia/Shanghai）
状态：Accepted

## Context

Phase 305 已把图片插入失败反馈绑定到发起页，但完全成功路径仍会无条件执行 `saveFailed = false`。异步多图
插入期间切页后，旧页的成功结果可能清掉新页的真实保存失败状态。

## Decision

只有捕获页 generation/pageId/currentPage 仍匹配且没有部分失败时，才清除 `saveFailed`。跨页成功保留持久化、
undo history 与 outcome，但不改变当前页的保存状态。失败反馈与 Phase 305 的页面绑定保持一致。
