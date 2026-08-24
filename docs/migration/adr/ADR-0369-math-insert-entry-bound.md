# ADR-0369：Math 插入入口状态绑定

- 状态：已接受（2026-08-25）
- 场景：`mathInsertSignal` 是跨组件异步入口；`startMathInsert()` 原有检查缺少 `lifecycleActive` 与 `loadedPageId === currentPage.pageId`。
- 决策：入口统一要求画布 active、加载健康、无忙碌冲突、持久化就绪，且实际加载页与当前页身份一致后才打开 Math 编辑器。
- 结果：销毁后或切页边界的迟到工具栏信号不再打开旧实例编辑器、取消选区或启动旧页验证；活动页插入语义不变。
