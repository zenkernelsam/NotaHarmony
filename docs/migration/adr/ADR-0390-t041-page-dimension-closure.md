# ADR-0390：T-041 存储页维度静态收口

- 状态：已接受（2026-08-25）
- 场景：T-041 记录的“client_op 无页维度、saveElements 先删整笔记、Notability 纵向平铺”已被后续架构淘汰，但任务文件仍保留未勾选验收框且没有完成报告，导致 Goal 无法证明该任务关闭。
- 决策：不改 Phase 1 契约，也不为已不存在的旧 API 添加别名。以当前 `page_info(note_id,page_id,page_index)` 和 `StrokePersistence.saveElements/loadElements(noteId,pageId)` 为权威契约；导入按页校验并写入，导出/编辑器/缩略图按 pageId 读取。补专项 Replay、完成报告和证据；模拟器崩溃验收明确由最终设备回归承接。
- 结果：T-041 从“代码看似完成但任务未收口”变为有静态证据的已完成项。T-042 仍保持整个 Goal 最后一项。
