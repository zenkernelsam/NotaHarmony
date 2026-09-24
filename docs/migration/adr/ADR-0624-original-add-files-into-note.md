# ADR-0624 编辑器「Add Files」物化进当前笔记（qc 序位第一 / qv5）

- 状态：Accepted
- 日期：2026-09-24
- 关联 Phase：657
- 接续：ADR-0619/0620/0621/0622（独立文件导入系列）、ADR-0623（Office fail-closed）
- 证据：`docs/migration/evidence/original-add-files-into-note-jadx-2026-09-24.md`

## 背景

原版编辑器插入菜单（`qc.java` case 0）序位为
**Add Files → Add Photo → Take Photo → [Add GIF] → [Math]**；
Add Files 是第一项，此前 Harmony 缺少该项且注释误记序位。
原版导入目标三态：`qv5=AddToExistingNote(noteId)`、
`sv5=CreateSingleNewNote`、`rv5=CreateSeparateNotes`；`yq8.g` 的 qv5
分支 `e(ttf,list)` 把与独立导入相同的 reducer ops 应用到既有笔记。
`ou5`/`vs5`/`st5`/`ss5` 还提供「导入目标选择」UI（选既有笔记 → qv5）。

## 决定

1. **入口**：EditorToolbar 插入菜单补 `add_files` 按钮并置于序位第一
   （非 compact 按钮行 + compact 菜单列表同序）；字符串补 base/zh_CN。
   `add_gif` 不实现（原版亦条件项，GIF 物化形态未单独立项）。
2. **管线**：`importFileIntoNoteFromPicker(context, noteId)` 复用
   DocumentViewPicker + fd 读取；`importFileIntoNote(noteId, bytes,
   fileName)` 按独立导入同序分发四类：
   - PDF → `importPdfIntoNote`：暂存→`parseImportedPdfPageSizes`→
     `storeImportedOriginalAsset`→`addImportedPage`×N，页码
     `baseIndex = existingPages.length` 起末尾追加，共享整文档
     sw9 寄存器（totalPageCount/pagesConsumed=PDF 页数）。
   - 图片 → `importImageIntoNote`：`prepareImportedImageBytes`
     （vuh.b 对齐）→ 资产入库 → 末尾追加 Letter 页 →
     `saveElements` 落 IMAGE 元素（kp5/baj.a 形态）。
   - 文本 → `importTextIntoNote`：空文本 fail-closed；末尾追加
     Letter 页 + TextBlockElement（te0/kci.b 形态）。
   - 音频 → `importAudioIntoNote`：pending 暂存 →
     `extractImportedAudioDuration` → `persistCapturedOriginalRecording`
     （自身置 `has_recordings` 并带失败清理）。
3. **追加语义**：`addPageInternal` 对无锚点导入按 `before.length`
   落页码，天然末尾追加；`yq8.e` 未反编译，按「同一 reducer 物化
   形态 + 末尾追加」落地并登记差异。
4. **失败回滚**：与独立导入删除整笔记不同，into-note 失败必须保
   既有笔记——`rollbackAppendedPages` 逆序 `deletePage` 已追加页
   （best-effort，逐条捕获）；音频走 persist 自带清理。
5. **fail-closed**：into-note 选择器不收 `.note`（归档并入既有笔记
   语义在 `yq8.d/e` 未反编译区，无法证明等价）；Office/RTF/Apple
   仍沿 ADR-0623 fail-closed；其余未映射后缀 `UNSUPPORTED_FORMAT`。
6. **编辑器刷新**：成功后 `pageRepo.getPages` 重载页列表、
   `pageContentVersion++` 触发缩略图重渲、`loadRecordings` 刷新
   录音时间线；共享 `photoImportLeaseActive` 入口租约，dispose 全程
   守卫。

## 后果

- 原版插入菜单五项中四项（Files/Photo/TakePhoto/Math）对齐；
  Add GIF 登记未实现。
- `.note` 不能并入打开的笔记（差异登记；若后续反编译补全
  `yq8.d/e` 可再评估）。
- 导入撤销：into-note 追加页走 `addImportedPage`（非历史 op），
  与原版 ops-reducer 路径不同——原版导入可能作为一组 op 入历史；
  Harmony 侧暂按非撤销物化，登记差异。
