# Harmony 证据：T-041 存储页维度静态收口

- 日期：2026-08-25
- 数据契约：`page_info` 已有 `note_id/page_id/page_index/width_mm/height_mm`，且 `(note_id,page_index)` 与
  `(note_id,page_id)` 都唯一。
- 写入：我方导入和 Notability 导入均为逐页 `addImportedPage()` 后调用 `saveElements(note.id, pageInfo.pageId,...)`；
  无整笔记 delete-all，无 flattenPages。
- 读取：导出器、编辑器和缩略图分别按 `p.pageId/targetPageId/page.pageId` 调用 `loadElements()`。
- Replay：`d02-t041-page-dimension-closure.mjs` 18/18 通过。
- 运行态说明：Goal 明确禁止模拟器/真机/Hypium；任务中的“模拟器不崩溃”不能在本阶段伪造为已测，
  已在完成报告中改为最终设备回归承接项。
