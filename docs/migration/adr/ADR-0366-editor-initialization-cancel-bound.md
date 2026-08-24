# ADR-0366：编辑器工具初始化取消绑定

- 状态：已接受（2026-08-25）
- 场景：`EditorViewModel.initialize()` 在保存链、工具读取、缺失写入、工具箱读取和设置读取后继续绑定状态或写共享 owner。
- 决策：调用方注入 `editorDisposed/loadGeneration` 门禁；ViewModel 在每个异步边界检查该门禁，陈旧初始化立即返回且不发布状态。
- 结果：销毁后的迟到初始化不会重建旧 UI 工具状态，也不会对共享 `'primary-editor'` 做持久化覆盖；活动页加载顺序与失败语义不变。
