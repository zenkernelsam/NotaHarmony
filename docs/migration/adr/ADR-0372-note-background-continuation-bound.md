# ADR-0372：笔记背景迟到续体绑定

- 状态：已接受（2026-08-25）
- 场景：`loadPages()` 在发布页列表后等待 `pageRepo.getNoteBackground()`，但 await 返回后没有销毁与加载代际检查就发布 `noteBackground`、重置页索引并进入录音加载；陈旧续体可覆盖新加载上下文。
- 决策：先将背景读取结果保存到局部值，await 返回后立即联合检查 `editorDisposed || loadGeneration !== this.pageLoadGeneration`，只有当前续体才发布背景并继续初始化页索引。
- 结果：销毁后或重叠 reload 的背景续体不再覆盖当前状态；durable 背景数据保持不变，正常加载路径和后续录音加载语义不变。
