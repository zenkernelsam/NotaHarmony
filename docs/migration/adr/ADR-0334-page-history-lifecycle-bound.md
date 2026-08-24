# ADR-0334：页面历史生命周期绑定

Status: Accepted - Phase 357（2026-08-24）

## Context

页面级 Undo/Redo 会先执行 durable repository 事务，再发布 pages、标题、背景、选择等编辑器状态。
Canvas 成功续体此前只看 `applied`；NotePage 的本地发布也没有在每次 durable await 后复查销毁态。
快速离开或重建编辑器时，迟到成功可能推进旧运行栈并触达已销毁实例。

## Decision

- `performHistory()` 在调用前捕获 `pageLoadGeneration`；成功续体必须同时保持 `lifecycleActive` 和相同
  generation 才能提交运行历史。
- 陈旧的 durable 成功只记录“durable history remains available”，不修改 undo/redo 栈。
- `NotePage.applyPageHistory()` 及 Add/Delete 子路径在每个主要 durable await 后检查 `editorDisposed`；
  销毁后的迟到成功返回 false，不发布任何本地状态。
- 失败与 busy 清理语义不变；durable 数据库结果继续权威。

## Consequences

旧实例不能跨销毁边界推进运行历史或改写 UI。下一次进入同一 note 时以持久层和权威加载恢复状态。
真实设备快速 Undo/Redo、切页与返回矩阵仍属后续验收范围。
