# T-041 存储层页维度修复（多页导入丢失 bug）

## 目标

修复 T-032 发现的既有 bug：`StrokePersistence.saveElements()` 无页维度且先 delete 全部记录，导致多页笔记导入只剩最后一页。同时消除 T-032 的"多页纵向平铺"退化方案。

## Bug 详情（T-032 报告第 10 节）

```
StrokePersistence.saveElements(noteId, elements)：
1. 开头 DELETE FROM client_op WHERE note_id = ?   ← 清空该笔记全部记录
2. 无 pageIndex/pageId 参数                        ← 无页维度

后果：
- importOurFormat() 逐页调用 saveElements → 后页清空前页 → 只剩最后一页
- importNotability() 被迫一次性写入 + flattenPages() 纵向平铺（退化方案）
```

## 实现要求

### 1. StrokePersistence 加页维度

修改 `note/src/main/ets/data/StrokePersistence.ets`：
- client_op 序列化 payload 中携带 pageIndex（或新增 page_index 列，DDL 用 ALTER/重建均可，注意幂等）
- 新增 `saveElementsForPage(noteId, pageIndex, elements)`：只 delete 该页记录再写入
- 新增 `loadElementsForPage(noteId, pageIndex)`
- 保留旧方法兼容（内部转调新方法）

### 2. 修复调用方

- `NoteImporter.importOurFormat()`：逐页 saveElementsForPage（不再丢页）
- `NoteImporter.importNotability()`：移除 flattenPages 平铺，逐页写入真实页号
- `NoteCanvasView` / `NoteExporter`：按当前页读写（保存当前页 → saveElementsForPage；导出 → 逐页 loadElementsForPage）

### 3. 数据迁移

旧数据（无页号记录）读取时默认归入第 0 页，不丢已有笔记。

## 验收标准

- [x] 我方格式多页笔记逐页解析、校验 pageIndex/pageId，并按唯一 pageId 落库；导出再导入可恢复独立页面。
- [x] Notability 格式按 Session 解析为真实页列表，每页分配唯一 pageId 并独立写入，无纵向平铺路径。
- [x] 旧数据迁移把 client_op 归属到既有 page_info.page_id，缺失页由迁移补默认页，不丢已有内容。
- [x] 编辑器翻页与缩略图均使用当前 noteId + targetPageId/pageId 读取对应内容。
- [x] ArkTS 静态检查通过；clean 与双 HAP 静态构建通过。本 Goal 禁止启动模拟器/Hypium，运行态崩溃验收由 T-042 前的最终设备验收统一执行。
- [x] 未修改 Phase 1 契约签名。

## 完成报告

`docs/migration/reports/T-041-完成.md`

## Phase 413 静态收口

- 权威证据：`page_info(note_id,page_id,page_index,width_mm,height_mm)`、`UNIQUE(note_id,page_index)`、
  `UNIQUE(note_id,page_id)`；`StrokePersistence.saveElements/loadElements` 以 pageId 为维度。
- 我方导入先全量验证 pageIndex/pageId 和跨页元素身份，再逐页 addImportedPage + saveElements；
  Notability 导入逐页分配新 ID 并写入 elementOrder，不存在 flattenPages 或 note 级 DELETE 重写。
- 导出、编辑器加载、缩略图渲染均按各自页面读取；专项 Replay 为
  `docs/migration/replays/d02-t041-page-dimension-closure.mjs`（18/18）。
