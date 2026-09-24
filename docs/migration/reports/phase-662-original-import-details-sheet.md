# Phase 662：原版导入详情页（ou5/zvh.a：目的地 + 逐文件题覆盖）

日期：2026-09-24
接续：Phase 661（外部共享/打开 PDF 入口）

## 原版依据

- `zvh.a(List, ttf, utf, …)`：共享导入详情 sheet，`u49`（编辑器
  Add Files）、`zvi`（库 Import）、`ib0`（共享 intent）三处复用；
  编辑器上下文 `ttf` 预置当前笔记。
- `ou5.l(ou5, tv5, list)`：`qv5 → N.c(uj(noteId))`；`sv5/rv5 →`
  逐文件 `ku5` 物化协程。
- `o1`（`fu5` 事件归约）：`wt5` 逐文件题（`lvd.b1(200, lvd.d1)`）、
  `st5 → qv5`、`tt5` 搜索、`yt5` 文件夹、`zt5.a` 确认。
- `qv5/sv5/rv5` payload：`AddToExistingNote(noteId)` /
  `CreateSingleNewNote(title,folderId)` /
  `CreateSeparateNotes(folderId,titleOverrides)`。
- 详见 `docs/migration/evidence/phase-662-original-import-details-sheet.md`
  与 ADR-0629。

## Harmony 实现

- `NoteImporter` 契约：`ImportFileDescriptor`/`ImportDestination`
  （SEPARATE_NOTES/SINGLE_NOTE/EXISTING_NOTE）/`ImportPlan`/
  `ImportSheetPrompt`，三个 picker（`importFromFile`、
  `importSharedUris`、`importFileIntoNoteFromPicker`）加可选
  `sheetPrompt` —— 未接线调用方保持 Phase 658 默认语义。
- `dispatchImportPlan`（`ou5.l` 对齐）：EXISTING →
  `importPickedFilesIntoNote`（编辑器上下文缺省回退当前笔记）；
  SINGLE → `importFilesIntoSingleNewNote`（`createNoteWithMeta`
  + 逐文件并入 + 全败 `removeFailedImport`）；SEPARATE →
  `importPickedFilesStandalone(..., titleOverrides)`。
- `titleOverride` 管道：PDF/图片/文本/音频四个 standalone 物化
  方法接受可选覆盖题；`normalizeImportTitleOverride` = trim+200，
  对齐 `lvd.b1(200, lvd.d1)`。
- `ImportDetailsSheet` 共享对话框：文件行、三目的地 chip、rv5
  逐行题、sv5 题+文件夹 chip、qv5 搜索+笔记列表、导入/取消；
  遮罩取消 → null（`cancel:` 回调，顺带修复密码对话框同类悬挂）。
- `LibraryPage`（picker + 共享 drain 均接线）、`NotePage`
  （`context='note'`，预选当前笔记 = `ttf` 语义）。`BackupPage`
  不经此 sheet（原版亦然）。

## 差异登记

- `.note` 归档在 sv5/qv5 路径维持 fail-closed（`yq8.d/e` 未反编译）。
- sheet 文件夹 chip 限 8、笔记列表限显 60（UI 预算）。
- sv5 多文件：原版逐文件协程入同一新笔记；Harmony 先建篇再并入，
  语义等价。

## 验证

- `d05-original-import-details-sheet.mjs`：53 断言。
- 更新 stale pin：`d05-original-shared-pdf-ingress`、
  `d05-original-pdf-file-import`、`d05-original-encrypted-pdf-import`、
  `d02-original-new-note-quick-actions`（签名/调用点演进）。
- 全量 Desktop Replay：547/547。
- `note@default` HAP 构建绿；clean + `note@ohosTest` 见提交记录。

## 文件清单

- `note/src/main/ets/data/NoteImporter.ets`
- `note/src/main/ets/ui/components/ImportDetailsSheet.ets`（新）
- `note/src/main/ets/ui/library/LibraryPage.ets`
- `note/src/main/ets/ui/editor/NotePage.ets`
- `note/src/main/resources/base/element/string.json`
- `note/src/main/resources/zh_CN/element/string.json`
- `docs/migration/replays/d05-original-import-details-sheet.mjs`（新）
- `docs/migration/evidence/phase-662-original-import-details-sheet.md`（新）
- `docs/migration/adr/ADR-0629-original-import-details-sheet.md`（新）
- 更新：`d05-original-shared-pdf-ingress.mjs`、
  `d05-original-pdf-file-import.mjs`、
  `d05-original-encrypted-pdf-import.mjs`、
  `d02-original-new-note-quick-actions.mjs`
