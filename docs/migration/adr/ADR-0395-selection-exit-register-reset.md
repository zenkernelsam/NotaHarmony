# ADR-0395：选区退出寄存器统一重置

- 状态：已接受（2026-08-25）
- 场景：Phase 416 只覆盖翻页成功；删除、剪切、显式取消、取消交互、加载失败、历史应用和数学插入等权威退出仍保留 NotePage 的 selection color/width/style，工具栏可继续回显旧上下文。
- 决策：新增 `clearSelectionWithRegisterReset()` 统一执行 SelectionTool 清空、选区浮层隐藏和 nullable 寄存器 reset。所有同页或失败态的权威选区退出都改用该助手。
- 结果：选区消失与命令寄存器默认态原子同步，避免后续样式、颜色或宽度 signal 消费 stale source；临时绘制开始、裁剪编辑和数学编辑保持选区语义的路径不重置。
