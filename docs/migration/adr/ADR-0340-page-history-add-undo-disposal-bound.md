# ADR-0340：增页撤销销毁绑定

Status: Accepted - Phase 363（2026-08-24）

## Context

`applyAddPageHistory()` 的 ADD_PAGE undo 分支在等待 `deletePage()` 后立即重排本地 `pages`
并恢复选择；redo、删页恢复和正向删页等页面历史主要 await 均已有销毁守卫。快速离开编辑器时，
durable 删除仍保持权威，但迟到成功可向已销毁 NotePage 发布旧页列表和选择。

## Decision

- ADD_PAGE undo 在 `pageRepo.deletePage()` await 后、任何本地状态发布前检查 `editorDisposed`。
- 销毁态返回既有 `false` 失败契约，不修改 pages 或选择，也不继续 history 续体语义。
- durable 数据库删除结果保持权威；redo 分支与失败处理不变。

## Consequences

旧 NotePage 不再跨销毁边界发布增页撤销结果。真实设备快速撤销矩阵仍属后续验收；本决策不启动
模拟器、虚拟机、真机或 Hypium。
