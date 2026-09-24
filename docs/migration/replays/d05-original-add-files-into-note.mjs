// Replay fixture — Phase 657：编辑器「Add Files」把文件物化进当前笔记
// （原版 qc 插入菜单序位第一 → qv5=AddToExistingNote → yq8.g qv5 分支 →
// e(ttf,list) 把与独立导入相同的 reducer ops 应用到既有笔记）。
// yq8.e 未反编译（837 指令跳过），Harmony 按同一 reducer 物化形态 +
// 末尾追加页/录音落地；.note/Office 仍 fail-closed。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';

const qc = fs.readFileSync(`${originalRoot}sources/defpackage/qc.java`, 'utf8');
const qv5 = fs.readFileSync(`${originalRoot}sources/defpackage/qv5.java`, 'utf8');
const sv5 = fs.readFileSync(`${originalRoot}sources/defpackage/sv5.java`, 'utf8');
const rv5 = fs.readFileSync(`${originalRoot}sources/defpackage/rv5.java`, 'utf8');
const yq8 = fs.readFileSync(`${originalRoot}sources/defpackage/yq8.java`, 'utf8');
const o1 = fs.readFileSync(`${originalRoot}sources/defpackage/o1.java`, 'utf8');
const ub2 = fs.readFileSync(`${originalRoot}sources/defpackage/ub2.java`, 'utf8');
const vs5 = fs.readFileSync(`${originalRoot}sources/defpackage/vs5.java`, 'utf8');
const st5 = fs.readFileSync(`${originalRoot}sources/defpackage/st5.java`, 'utf8');

const importer = fs.readFileSync('note/src/main/ets/data/NoteImporter.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const toolbar = fs.readFileSync('note/src/main/ets/ui/editor/EditorToolbar.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const notePage = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const stringsBase = fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const stringsZh = fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

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

// ── 原版证据：qc 插入菜单 Add Files 序位第一 ────────────────────────────
const addFilesPos = qc.indexOf('feature_note_toolbox__add_files');
const addPhotoPos = qc.indexOf('feature_note_toolbox__add_photo');
const takePhotoPos = qc.indexOf('feature_note_toolbox__take_photo');
const insertMathPos = qc.indexOf('feature_note_toolbox__insert_math');
check(addFilesPos !== -1 && addPhotoPos !== -1 && takePhotoPos !== -1 &&
  insertMathPos !== -1, 'qc lists all four insert strings');
check(addFilesPos < addPhotoPos && addPhotoPos < takePhotoPos &&
  takePhotoPos < insertMathPos,
  'qc order: add_files → add_photo → take_photo → insert_math');
check(qc.includes('feature_note_toolbox__add_gif'), 'qc has conditional add_gif');

// ── 原版证据：三种导入目标 ────────────────────────────────────────────
check(qv5.includes('AddToExistingNote(noteId='), 'qv5 = AddToExistingNote(noteId)');
check(sv5.includes('CreateSingleNewNote'), 'sv5 = CreateSingleNewNote');
check(rv5.includes('CreateSeparateNotes'), 'rv5 = CreateSeparateNotes');

// ── 原版证据：yq8.g 的 qv5 分支 → e(ttf,list) ──────────────────────────
check(yq8.includes('tv5Var instanceof qv5'), 'yq8.g dispatches qv5');
check(/qv5\)\s*\.a\(\)[\s\S]{0,200}e\(ttfVarA2?,/.test(yq8) ||
  yq8.includes('e(ttfVarA, list, xq8Var)') || yq8.includes('e(ttfVarA2, list, xq8Var)'),
  'yq8.g qv5 branch calls e(ttf,list)');
check(yq8.includes('NTB selection must be homogeneous'), 'NTB homogeneity guard');

// ── 原版证据：导入目标选择流（ou5 状态机经 o1/ub2 lambda 发出 qv5） ────
check(o1.includes('new qv5') || ub2.includes('new qv5'), 'ou5 lambdas emit qv5');
check(vs5.includes('new st5'), 'vs5 maps note pick to st5');
check(st5.includes('this.a = ttfVar'), 'st5 carries the target note ttf');

// ── Harmony：importFileIntoNote 分发 ───────────────────────────────────
const intoNote = section(importer, 'async importFileIntoNote(', 'private async rollbackAppendedPages');
check(intoNote.includes('importPdfIntoNote') && intoNote.includes('importImageIntoNote') &&
  intoNote.includes('importTextIntoNote') && intoNote.includes('importAudioIntoNote'),
  'importFileIntoNote dispatches all four types');
check(intoNote.indexOf('importPdfIntoNote') < intoNote.indexOf('importImageIntoNote') &&
  intoNote.indexOf('importImageIntoNote') < intoNote.indexOf('importTextIntoNote') &&
  intoNote.indexOf('importTextIntoNote') < intoNote.indexOf('importAudioIntoNote'),
  'into-note dispatch order mirrors standalone');
check(intoNote.includes('UNSUPPORTED_FORMAT'), 'unmapped types fail closed');
check(intoNote.includes('noteId.length === 0'), 'empty noteId rejected');

// ── Harmony：into-note picker（无 .note） ──────────────────────────────
const pickerInto = section(importer, 'importFileIntoNoteFromPicker', 'return await this.importFileIntoNote(noteId');
check(pickerInto.includes('fileSuffixFilters'), 'into-note picker filters');
check(!pickerInto.includes("'.note'"), 'into-note picker excludes .note');
check(pickerInto.includes("'.pdf'") && pickerInto.includes("'.png'") &&
  pickerInto.includes("'.txt'") && pickerInto.includes("'.mp3'"),
  'into-note picker accepts pdf/image/text/audio');

// ── Harmony：追加语义与回滚 ────────────────────────────────────────────
const pdfInto = section(importer, 'private async importPdfIntoNote', 'private async importImageIntoNote');
check(pdfInto.includes('existingPages.length') && pdfInto.includes('baseIndex + index'),
  'pdf pages append at note end');
check(pdfInto.includes('storeImportedOriginalAsset') && pdfInto.includes('addImportedPage'),
  'pdf into-note stores asset + imported pages');
check(pdfInto.includes('rollbackAppendedPages'), 'pdf failure rolls back appended pages');

const imgInto = section(importer, 'private async importImageIntoNote', 'private async importTextIntoNote');
check(imgInto.includes('prepareImportedImageBytes') && imgInto.includes('buildImportedImageElement'),
  'image into-note reuses vuh.b-aligned prep + kp5 element');
check(imgInto.includes('saveElements'), 'image into-note writes elements on appended page');

const txtInto = section(importer, 'private async importTextIntoNote', 'private async importAudioIntoNote');
check(txtInto.includes('buildImportedTextElement') && txtInto.includes('text.length === 0'),
  'text into-note reuses tu5 path + empty fail-closed');

const audInto = section(importer, 'private async importAudioIntoNote', 'private async importOurFormat');
check(audInto.includes('persistCapturedOriginalRecording') &&
  audInto.includes('audioMimeForFileName') && audInto.includes('extractImportedAudioDuration'),
  'audio into-note reuses izi.M persistence + duration extraction');

// ── Harmony：插入菜单 UI ──────────────────────────────────────────────
const toolbarFiles = toolbar.indexOf("app.string.add_files");
const toolbarPhoto = toolbar.indexOf("app.string.insert_photo");
check(toolbarFiles !== -1 && toolbarPhoto !== -1 && toolbarFiles < toolbarPhoto,
  'toolbar: Add Files precedes Add Photo');
check(toolbar.includes('onAddFiles'), 'toolbar exposes onAddFiles');
check(stringsBase.includes('"add_files"') && stringsZh.includes('"add_files"'),
  'add_files string in base + zh_CN');

// ── Harmony：NotePage 接线 ────────────────────────────────────────────
check(notePage.includes('onAddFiles') && notePage.includes('importFileIntoCurrentNote'),
  'NotePage wires onAddFiles → importFileIntoCurrentNote');
const handler = section(notePage, 'private async importFileIntoCurrentNote',
  'private async persistCapturedRecording');
check(handler.includes('importFileIntoNoteFromPicker') && handler.includes('getPages') &&
  handler.includes('loadRecordings') && handler.includes('pageContentVersion++'),
  'handler refreshes pages, thumbnails and recordings');
check(handler.includes('photoImportLeaseActive = false'), 'handler releases ingress lease');

console.log(`D05_ORIGINAL_ADD_FILES_INTO_NOTE_REPLAY_OK TOTAL=${total} FAILED=0`);
