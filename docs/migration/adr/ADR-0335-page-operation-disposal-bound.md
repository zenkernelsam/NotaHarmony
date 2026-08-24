# ADR-0335：页面操作销毁绑定

Status: Accepted - Phase 358（2026-08-24）

## Context

正向页面操作会先提交 durable 数据库事务，再发布本地 pages、选择、背景并推入运行 undo 栈。背景更新、
增页、删页和重排的成功续体此前没有复查 `editorDisposed`；快速离开编辑器时，迟到成功仍可触达旧 UI 和
运行历史。Phase 357 只覆盖了反向执行同一批 action 的 history 路径。

## Decision

- 每个主要 durable await 后检查 `editorDisposed`；销毁后的迟到成功直接返回。
- 陈旧续体不修改 action、pages、selection 或 note background，也不调用 history bridge push。
- 删除路径的失败回滚继续无条件取消 page removal；busy 清理和既有错误提示语义不变。
- durable 数据库结果保持权威，下一次活动页加载负责恢复。

## Consequences

旧实例不能跨销毁边界发布正向页面变更。真实设备快速增删页、重排与返回矩阵仍属后续验收范围；
本决策不启动任何设备或 Hypium。
