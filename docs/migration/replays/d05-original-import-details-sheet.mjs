// Phase 662 — 原版 ou5/zvh.a 导入详情页：文件行 + tv5 目的地
// （qv5 现有笔记 / sv5 新建笔记 / rv5 各自笔记）+ fu5 事件
// （wt5 逐文件题、tt5 搜索、st5 选笔记、yt5 选文件夹、zt5 确认）。
// 原版证据（decompiled_1.0.3）：
//   zvh.java      zvh.a(List files, ttf, utf, String, ix4, Function0 dismiss,
//                Function1 onPassword, t42, ...)：共享导入详情 sheet，
//                编辑器（u49）与库（zvi）两个上下文复用；
//   ou5.java      ou5.l(ou5, tv5, list)：qv5 → N.c(new uj(noteId))；
//                sv5/rv5 → 逐文件 ku5 协程物化；
//   o1.java       fu5 事件归约：wt5 → lvd.b1(200, lvd.d1(title)) 逐文件题；
//                st5 → new qv5(noteId)；tt5 → X.j(query)；
//                yt5 → new iq4(folderId)；zt5.a = OnImportClicked；
//   qv5/sv5/rv5   AddToExistingNote(noteId) /
//                CreateSingleNewNote(title,folderId) /
//                CreateSeparateNotes(folderId,titleOverrides) payload。
// Harmony 对齐：ImportPlan/ImportSheetPrompt 契约 + dispatchImportPlan
//   三分支分发 + ImportDetailsSheet 共享对话框；LibraryPage（含共享
//   入口）与 NotePage Add Files 走同一详情页；未接 sheetPrompt 的旧
//   调用方保持原默认语义。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const ou5 = fs.readFileSync(`${originalRoot}sources/defpackage/ou5.java`, 'utf8');
const o1 = fs.readFileSync(`${originalRoot}sources/defpackage/o1.java`, 'utf8');
const zvh = fs.readFileSync(`${originalRoot}sources/defpackage/zvh.java`, 'utf8');
const qv5 = fs.readFileSync(`${originalRoot}sources/defpackage/qv5.java`, 'utf8');
const sv5 = fs.readFileSync(`${originalRoot}sources/defpackage/sv5.java`, 'utf8');
const rv5 = fs.readFileSync(`${originalRoot}sources/defpackage/rv5.java`, 'utf8');
const zt5 = fs.readFileSync(`${originalRoot}sources/defpackage/zt5.java`, 'utf8');

const importer = fs.readFileSync('note/src/main/ets/data/NoteImporter.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const sheet = fs.readFileSync('note/src/main/ets/ui/components/ImportDetailsSheet.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const library = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const editor = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const baseStrings = fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zhStrings = fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}
function section(source, startMarker, endMarker) {
  const start = source.indexOf(startMarker);
  const end = source.indexOf(endMarker, start);
  assert.ok(start !== -1 && end > start, startMarker);
  return source.slice(start, end);
}

// ---------- 原版证据 ----------
check(zvh.includes('public static final void a(List list, ttf ttfVar, utf utfVar'),
  'zvh.a is the shared import-details sheet entry (files + destination + callbacks)');
const ou5l = section(ou5, 'public static final void l(ou5 ou5Var, tv5 tv5Var, List list)',
  'public final void f()');
check(ou5l.includes('tv5Var instanceof qv5') &&
  ou5l.includes('ou5Var.N.c(new uj(((qv5) tv5Var).a()))'),
  'ou5.l routes qv5 AddToExistingNote to the note-id consumer');
check(ou5l.includes('tv5Var instanceof sv5') && ou5l.includes('tv5Var instanceof rv5') &&
  ou5l.includes('new ku5('),
  'ou5.l iterates sv5/rv5 file lists into per-file import coroutines');
check(qv5.includes('AddToExistingNote(noteId=') && qv5.includes('public final ttf a'),
  'qv5 carries the existing-note id payload');
check(sv5.includes('CreateSingleNewNote(title=') && sv5.includes('folderId='),
  'sv5 carries title + folderId payload');
check(rv5.includes('CreateSeparateNotes(folderId=') && rv5.includes('titleOverrides=') &&
  rv5.includes('public final Map b'),
  'rv5 carries folderId + per-file titleOverrides map');
check(o1.includes('fu5Var instanceof wt5') && o1.includes('lvd.b1(200'),
  'o1 caps wt5 per-file title overrides at 200 chars (lvd.b1(200))');
check(o1.includes('fu5Var instanceof st5') &&
  o1.includes('new qv5(((st5) fu5Var).a)'),
  'o1 turns st5 note selection into a qv5 destination');
check(o1.includes('fu5Var instanceof tt5') && o1.includes('X.j(((tt5) fu5Var).a)'),
  'o1 routes tt5 to the note-search query store');
check(o1.includes('fu5Var instanceof yt5') &&
  o1.includes('new iq4(((yt5) fu5Var).a)'),
  'o1 routes yt5 to the folder selection store');
check(o1.includes('fu5Var.equals(zt5.a)') && zt5.includes('OnImportClicked'),
  'zt5.a is the OnImportClicked confirm event');

// ---------- Harmony 契约 ----------
check(importer.includes('export interface ImportFileDescriptor') &&
  importer.includes('export interface ImportPlan') &&
  importer.includes('export type ImportSheetPrompt'),
  'importer exports the ImportFileDescriptor/ImportPlan/ImportSheetPrompt contract');
check(importer.includes('export enum ImportDestination') &&
  importer.includes('SEPARATE_NOTES = 0') &&
  importer.includes('SINGLE_NOTE = 1') &&
  importer.includes('EXISTING_NOTE = 2'),
  'ImportDestination enumerates rv5/sv5/qv5 semantics');
check(importer.includes('titleOverrides: Map<string, string>') &&
  importer.includes('singleTitle: string') &&
  importer.includes('folderId: string | null') &&
  importer.includes('noteId: string;'),
  'ImportPlan carries noteId/folderId/singleTitle/titleOverrides fields');

// ---------- 分发（ou5.l 对齐）----------
const dispatch = section(importer, 'private async dispatchImportPlan',
  'private async importFilesIntoSingleNewNote');
check(dispatch.includes('plan.destination === ImportDestination.EXISTING_NOTE') &&
  dispatch.includes('await this.importPickedFilesIntoNote(target, uris, passwordPrompt)'),
  'dispatchImportPlan routes EXISTING_NOTE to the into-note loop (qv5)');
check(dispatch.includes('plan.destination === ImportDestination.SINGLE_NOTE') &&
  dispatch.includes('await this.importFilesIntoSingleNewNote'),
  'dispatchImportPlan routes SINGLE_NOTE to the create+merge path (sv5)');
check(dispatch.includes('await this.importPickedFilesStandalone(uris, passwordPrompt,') &&
  dispatch.includes('plan.titleOverrides'),
  'dispatchImportPlan routes SEPARATE_NOTES with titleOverrides (rv5)');
const singleNew = section(importer, 'private async importFilesIntoSingleNewNote',
  '// 原版 ALLOW_MULTIPLE + rv5 CreateSeparateNotes');
check(singleNew.includes('noteRepo.createNoteWithMeta') &&
  singleNew.includes('folderId') &&
  singleNew.includes('await this.importPickedFilesIntoNote(note.id, uris, passwordPrompt)'),
  'sv5 path creates one note (title+folderId) then merges all picked files');
check(singleNew.includes('await this.removeFailedImport(note.id)'),
  'sv5 path cleans up the empty note when every file fails');
const standalone = section(importer, 'private async importPickedFilesStandalone',
  'private async importPickedFilesIntoNote');
check(standalone.includes('titleOverrides?: Map<string, string>') &&
  standalone.includes('normalizeImportTitleOverride(titleOverrides.get(uri))'),
  'rv5 loop resolves a normalized per-file title override by uri');
check(importer.includes('function normalizeImportTitleOverride') &&
  importer.includes('trimmed.slice(0, 200)'),
  'title overrides are trimmed and capped at 200 chars (o1 lvd.b1(200))');

// ---------- titleOverride 管道 ----------
check(importer.includes('titleOverride?: string): Promise<ImportReport>'),
  'standalone import methods accept an optional titleOverride');
const overrideUses = importer.match(/titleOverride !== undefined && titleOverride\.length > 0/g) || [];
check(overrideUses.length >= 4,
  'PDF/image/text/audio title sites honor titleOverride (>=4 sites)');
check(importer.includes('titleOverride : pdfImportTitle(fileName)') &&
  (importer.match(/titleOverride : importedFileStemTitle\(fileName\)/g) || []).length === 3,
  'PDF falls back to pdfImportTitle; image/text/audio fall back to file stem');

// ---------- picker 接详情页 ----------
check(importer.includes('sheetPrompt?: ImportSheetPrompt'),
  'pickers accept an optional ImportSheetPrompt');
check(importer.includes("await sheetPrompt(describeImportUris(uris), 'standalone', '')"),
  'standalone/shared pickers hand descriptors to the sheet in standalone context');
check(importer.includes("await sheetPrompt(describeImportUris(uris), 'note', noteId)"),
  'editor picker hands descriptors to the sheet in note context');
check(importer.includes('function describeImportUris') &&
  importer.includes('fileIo.statSync(uri).size'),
  'describeImportUris builds file rows from uri/name/size without reading bytes');

// ---------- 共享对话框 ----------
check(sheet.includes('export struct ImportDetailsSheet') &&
  sheet.includes('files: ImportFileDescriptor[]') &&
  sheet.includes('onResult: (plan: ImportPlan | null) => void'),
  'ImportDetailsSheet takes file descriptors and resolves an ImportPlan');
check(sheet.includes('ImportDestination.EXISTING_NOTE') &&
  sheet.includes('ImportDestination.SINGLE_NOTE') &&
  sheet.includes('ImportDestination.SEPARATE_NOTES'),
  'sheet offers the three original destinations');
check(sheet.includes('this.context === \'note\'') &&
  sheet.includes('this.selectedNoteId = this.currentNoteId'),
  'note context preselects the current note as the qv5 target');
check(sheet.includes('@State titleDrafts') &&
  sheet.includes('this.titleDrafts = drafts') &&
  sheet.includes('titleOverrides: overrides'),
  'sheet tracks per-file title drafts (wt5) and emits titleOverrides');
check(sheet.includes('noteSearch') && sheet.includes('filteredNotes'),
  'sheet provides note search for the qv5 picker (tt5)');
check(sheet.includes('this.folderId = folder.id'),
  'sheet provides folder selection for sv5/rv5 (yt5)');
check(sheet.includes('this.finish(null)') &&
  sheet.includes('this.confirm()'),
  'sheet resolves null on cancel and a plan on zt5 confirm');

// ---------- 页面接线 ----------
check(library.includes('this.importSheetPrompt') &&
  library.includes('importSharedUris(uris, this.pdfPasswordPrompt,') &&
  library.includes('importFromFile(context, this.pdfPasswordPrompt,'),
  'LibraryPage wires the sheet into picker + shared-ingress imports');
check(library.includes('getAllNotes()') && library.includes('getAllFolders()'),
  'LibraryPage loads the full note/folder lists for the sheet');
check(editor.includes('importFileIntoNoteFromPicker(context, this.noteId,') &&
  editor.includes('this.importSheetPrompt'),
  'NotePage wires the sheet into the Add Files picker');
check(library.includes('importSheetDialog.open()') &&
  editor.includes('importSheetDialog.open()'),
  'both pages present the sheet through a CustomDialogController');

// ---------- 字符串 ----------
for (const key of ['import_details_title', 'import_dest_separate',
  'import_dest_single', 'import_dest_existing', 'import_note_title_hint',
  'import_folder_none', 'import_confirm']) {
  check(baseStrings.includes(`"name": "${key}"`),
    `base strings define ${key}`);
  check(zhStrings.includes(`"name": "${key}"`),
    `zh_CN strings define ${key}`);
}

console.log(`D05_ORIGINAL_IMPORT_DETAILS_SHEET_OK TOTAL=${total} FAILED=0`);
