# ADR-0328：原版文本最终提交陈旧绑定

Status: Accepted - Phase 351（2026-08-24）

## Context

NoteCanvasView 销毁时可能异步执行文本框最终提交。该路径会先 preview 原版 Text CRDT 样式；await 后只检查
元素身份和页面上下文，没有检查本次提交是否已被更新提交取代。销毁后的迟到续体仍可替换元素、入历史并触发保存。

## Decision

- 每次进入 `onTextCommit()` 时捕获新的 text commit generation。
- 原版 Text 编辑在样式 preview await 后，必须同时校验提交代数、编辑元素身份、页面加载代数、页面 ID 和
  `lifecycleActive`。
- 任一陈旧条件成立即拒绝提交，不修改内存 Ink、不入 Undo/Redo、不触发持久化。
- 非 Original 文本同步路径保持不变；`historyBusy` 重复提交门禁保留。

## Consequences

最终提交不能被销毁或后续提交的过期续体覆盖。durable Text 操作与 CRDT 样式权威保持不变。
真实设备快速返回、连续提交和进程恢复矩阵继续独立开放。
