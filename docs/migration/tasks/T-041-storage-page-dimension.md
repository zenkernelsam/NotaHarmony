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

- [ ] 我方格式多页笔记（3 页各画笔画）→ 导出 → 删除 → 导入 → 3 页内容全部恢复
- [ ] Notability 格式导入（OP-AMP.note）→ 3 页独立显示（不再纵向平铺）
- [ ] 旧笔记（升级前数据）打开不丢内容
- [ ] 翻页时画布正确显示对应页内容
- [ ] `check_ets_files` + `build_project` 通过 + 模拟器不崩溃
- [ ] 不修改 Phase 1 契约文件

## 完成报告

`docs/migration/reports/T-041-完成.md`
