# ADR-1359：Unindexed Notes 管理对话框（l8n.h 移植）

## 状态
Accepted — Phase 1423

## 背景
原版图库 `flc/vhf` 索引状态横幅中 "N unindexed note(s)" 支的
Learn More（`zsb` → `l8n.h`）并非纯说明弹窗，而是**可选列表 +
Index Notes 重建动作**的管理对话框：

- `l8n.h`（m8n.a 对话框）承载 `p6f` case15：LazyColumn 列表
  （粘性头 = 标题+说明）、底栏 Select All/Deselect All + "N notes
  selected" 计数、Close / Index Notes 按钮对。
- `zsb` 初始选集 = 全部 unindexed id。
- `y73`/`z73`/`dsb`：Index Notes（enabled=选集非空）→ 协程重建
  所选 → dismiss；Close → 仅 dismiss。

Harmony 此前仅有 `unindexedNoteCount` 计数横幅 + 纯说明对话框
（Close），unindexed 笔记没有任何重建入口 —— 一旦导入中断造成
search_item 缺失，该笔记将永久缺席搜索。

## 决策
移植 `l8n.h` 全部件：

1. `NoteRepository` 新增 `getUnindexedNotes()` 与
   `reindexUnindexedNotes(noteIds)`；后者按笔记事务化重建 TITLE +
   TEXT_BLOCK `search_item`（源 = `page_element_snapshot` 持久化
   payload，经新导出的 `searchTextForElement`）并写
   `search_page_state.indexed_revision`。
2. `LibraryViewModel` 新增 `unindexedNotes`（与计数同批加载）与
   `reindexUnindexedNotes`（enqueueMutation + 刷新）。
3. `UnindexedNotesDialog` 由纯说明升级为管理对话框：固定标题+
   说明、可选笔记行（checkmark_circle/circle_empty_med_outline +
   标题 + updatedAt 日期，select_note a11y）、Select All/
   Deselect All 文本行、"N notes selected" 复数计数、Close +
   Index Notes（默认全选，enabled=选集非空）。

## 忠实边界（fail-closed）
- **INK 搜索项**：源 = 识别服务输出（`replaceImportedHandwritingText`
  等），未持久化可重放输入 → 重建不覆盖。
- **PDF 搜索项**：源 = 导入期 pdfService 文本抽取 → 同上。
- **索引进度态**（"Indexing N notes"/"All notes indexed"）：
  Harmony 索引为同步落库，无 `whf` 队列语义 → 不渲染进度横幅。
- 笔记若在重建间被删除/不存在，`reindexUnindexedNotes` 跳过该 id
  并继续（逐笔记事务）。

## 影响
- 数据层只读扩列 + 幂等重建写入；对已索引笔记零影响
  （谓词 NOT EXISTS 保证仅零索引行入选）。
- `UnindexedNotesDialog` 签名扩展（getNotes/onIndexNotes），
  LibraryPage 单点接线。
- Replay：`d02-original-unindexed-notes-dialog.mjs` 26 项断言。
