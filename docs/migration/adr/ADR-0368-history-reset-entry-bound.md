# ADR-0368：历史恢复入口状态绑定

- 状态：已接受（2026-08-25）
- 场景：历史恢复对话框的 reset 回调可能迟到执行；旧实现直接调用 `resetPersistentHistory()`，点击瞬间缺少 `lifecycleActive` 与忙碌复查。
- 决策：新增 `requestPersistentHistoryReset()` 作为唯一对话框入口；请求前联合检查 active、required、recovery busy、history busy 和 database。
- 结果：销毁后或历史命令进行中的迟到确认静默返回，不再绕过串行化清空共享 undo 栈；活动页恢复语义与 durable 失败处理不变。
