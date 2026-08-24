# ADR-0371：笔记零页恢复销毁绑定

- 状态：已接受（2026-08-25）
- 场景：legacy/corrupt 零页恢复路径在 `pageRepo.addPage()` 等待返回后直接发布 `this.pages`，缺少销毁与加载代际门禁；dispose-before-return 或重叠 reload 的陈旧续体可覆盖新上下文页状态。
- 决策：在恢复 `addPage()` await 之后、内存发布之前联合检查 `editorDisposed || loadGeneration !== this.pageLoadGeneration`；不满足则静默返回，保留已写入的 durable 恢复页。
- 结果：陈旧续体不再覆盖新加载或销毁后的页面状态；正常加载分支、后续背景读取、失败处理与 finally 清理语义不变。
