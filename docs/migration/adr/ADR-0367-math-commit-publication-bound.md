# ADR-0367：Math 提交发布页面绑定

- 状态：已接受（2026-08-25）
- 场景：Math LaTeX 更新与插入的 durable commit 迟到返回时，既有 stale guard 会阻断内存发布，但仍推进 undo 栈并全局通知撤销状态。
- 决策：提交后的 undo action 只在 `isHistoryPageContextCurrent()` 通过后构造并 push；`lastQueuedHistoryRevision`、编辑器清理和 `notifyUndoRedo()` 同样留在当前页上下文内。
- 结果：陈旧成功续体保留 durable 数据与日志，但不污染旧实例撤销栈，也不向新页面广播旧撤销状态；活动页成功语义不变。
