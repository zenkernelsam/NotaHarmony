# ADR-0287: Bind Math Save Clear To The Editing Page

日期：2026-08-23（Asia/Shanghai）
状态：Accepted

## Context

Math LaTeX 编辑和插入在异步 SQLite 提交后无条件清 `saveFailed`。若提交期间切页，旧页迟到成功会误清新页的真实
保存失败状态；这与 Phase 305–308 建立的页面状态边界不一致。

## Decision

只有捕获页 generation/pageId/currentPage 匹配时才清 `saveFailed`。跨页成功仍推进数据库与 undo history，并完成
editor 关闭/草稿清理，但不改变当前页的保存状态。失败路径继续同页报告。
