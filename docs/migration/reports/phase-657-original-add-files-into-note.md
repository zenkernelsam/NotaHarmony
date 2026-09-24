# Phase 657：编辑器「Add Files」物化进当前笔记（qc 序位第一 / qv5）

日期：2026-09-24
接续：Phase 656（Office/RTF/Apple 文档导入 fail-closed）

## 原版依据

- `qc.java`（case 0）：编辑器插入菜单序位 **Add Files → Add Photo →
  Take Photo → [Add GIF] → [Math]**；Add Files 是第一项。
- `ou5`/`o1`/`ub2`/`vs5`/`st5`/`ss5`：导入目标选择流——选中既有笔记
  `ttf` → `st5` → `qv5(noteId)`（AddToExistingNote）。
- `yq8.g`：qv5 分支 `e(ttf,list)`（未反编译，837 指令跳过）把与
  独立导入相同的负载（`su5/qu5/tu5/pu5`）物化进既有笔记。
- 详细 JADX 摘录见 `docs/migration/evidence/original-add-files-into-note-jadx-2026-09-24.md`。

## Harmony 实现

1. **入口**（`EditorToolbar.ets`）：插入菜单新增 `add_files` 按钮，
   置于序位第一（按钮行与 compact 菜单同序），接入 `onAddFiles` 回调，
   复用 `photoImportLeaseActive` 租约守卫；`string.json`（base/zh_CN）
   补 `add_files`。
2. **管线**（`NoteImporter.ets`）：
   - `importFileIntoNoteFromPicker(context, noteId)`：DocumentViewPicker
     过滤 PDF/图片/txt/音频后缀（**不收 `.note`**），fd 读取 + 尺寸/空文件
     检查 + `finally` 关句柄。
   - `importFileIntoNote(noteId, bytes, fileName)`：PDF magic/后缀 →
     `importPdfIntoNote`；图片后缀 → `importImageIntoNote`；`.txt` →
     `importTextIntoNote`；音频后缀 → `importAudioIntoNote`；其余
     `UNSUPPORTED_FORMAT`（Office 等沿 ADR-0623 fail-closed）。
   - `importPdfIntoNote`：`baseIndex = existingPages.length` 起按 PDF
     页数追加，共享整文档 sw9 寄存器；失败 `rollbackAppendedPages` 逆序
     删页 + 资产清理，保既有笔记。
   - `importImageIntoNote`/`importTextIntoNote`：末尾追加 Letter 页 +
     IMAGE/文本元素（kp5/baj.a、te0/kci.b 形态）；失败删页回滚。
   - `importAudioIntoNote`：pending 暂存 → 时长探测 →
     `persistCapturedOriginalRecording`（置 has_recordings + 自带清理）；
     不产生新页。
3. **编辑器接线**（`NotePage.ets`）：`importFileIntoCurrentNote` 调
   importer → 成功后 `pageRepo.getPages` 重载 + `pageContentVersion++` +
   `loadRecordings`；dispose 全程守卫；租约 `finally` 释放。

## 与原版差异（登记，ADR-0624）

- **追加锚点**：`yq8.e` 未反编译，按「同一物化形态 + 末尾追加」落地。
- **`.note` 不并入既有笔记**：归档并入语义在 `yq8.d/e` 未反编译区，
  fail-closed。
- **撤销**：追加页走 `addImportedPage`（非历史 op），原版可能以 op
  组入历史——暂按非撤销物化。
- **Add GIF**：原版条件项，本阶段未实现（另行立项评估）。
- **目标选择 UI**：原版 `ss5` 还支持从库内导入选既有笔记；本阶段仅
  补编辑器入口，库内「导入到既有笔记」仍按独立导入建笔记。

## 验证

- 桌面回放：`d05-original-add-files-into-note.mjs` 32 断言绿；
  全量套件见提交信息。
- HAP：`note@ohosTest` / `note@default` clean 构建通过（见提交信息）。
