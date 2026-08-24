# ADR-0373：笔记加载准入顺序绑定

- 状态：已接受（2026-08-25）
- 场景：`loadPages()` 原先先递增 `pageLoadGeneration`，再检查销毁态与 in-flight；被拒绝的重复或销毁后调用仍会使正在执行的当前代失效，导致活动加载在后续异步边界静默取消。
- 决策：把 `editorDisposed || pageLoadInFlight` 准入检查移到加载代际递增之前；只有获得执行权的调用才创建新代并设置 in-flight。
- 结果：重复 retry、销毁前迟到入口和重入调用不会取消活动加载；既有每个 await 后的销毁/代际门禁、失败回滚与 finally 清理保持不变。
