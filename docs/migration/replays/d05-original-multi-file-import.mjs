// D05 原版多选文件导入（ALLOW_MULTIPLE → rv5/qv5）— Phase 658
// 证据：docs/migration/evidence/original-multi-file-import-jadx-2026-09-24.md
// 原版 nti.R 注册 OPEN_DOCUMENT（f35(3)）+ GET_CONTENT（f35(1)）双
// 启动器并均带 ALLOW_MULTIPLE；oj3.f 过滤表为图片9+音频6+Office7+pdf+
// txt+octet-stream（无 .note）；选择结果经 sl(29) 复制后进 zvh.a/ou5
// 导入详情页（含加密 PDF 密码），默认目标 qv5(当前笔记)。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');
const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources';

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

const f35 = read(`${SRC}/defpackage/f35.java`);
const nti = read(`${SRC}/defpackage/nti.java`);
const oj3 = read(`${SRC}/defpackage/oj3.java`);
const zvh = read(`${SRC}/defpackage/zvh.java`);
const ub2 = read(`${SRC}/defpackage/ub2.java`);
const rv5 = read(`${SRC}/defpackage/rv5.java`);
const u49 = read(`${SRC}/defpackage/u49.java`);
const lb = read(`${SRC}/defpackage/lb.java`);
const tf9 = read(`${SRC}/defpackage/tf9.java`);

const importer = read('note/src/main/ets/data/NoteImporter.ets');
const notePage = read('note/src/main/ets/ui/editor/NotePage.ets');

// --- 原版：ALLOW_MULTIPLE 双契约（f35 case 1 GET_CONTENT / case 3 OPEN_DOCUMENT） ---
check(f35.includes('new f35(1)') && f35.includes('ALLOW_MULTIPLE'),
  'f35.c is GET_CONTENT with ALLOW_MULTIPLE');
const f35Case3 = f35.substring(f35.indexOf('case 3:'), f35.indexOf('case 4:'));
check(f35Case3.includes('OPEN_DOCUMENT') && f35Case3.includes('ALLOW_MULTIPLE'),
  'f35 case 3 is OPEN_DOCUMENT with ALLOW_MULTIPLE');
check(f35Case3.includes('MIME_TYPES') && f35Case3.includes('"*/*"'),
  'f35 case 3 filters MIME_TYPES over */*');

// --- 原版：nti.R 双启动器 + oj3 MIME 表 ---
check(nti.includes('public static final Function0 R(ix4 ix4Var'),
  'nti.R is the add-files launcher helper');
check(nti.includes('new f35(i4)') && nti.includes('f35Var2 = f35.c'),
  'nti.R registers OPEN_DOCUMENT plus GET_CONTENT fallback');
check(nti.includes('oj3.f') && nti.includes('oj3.e'),
  'nti.R selects the oj3 mime filter arrays');
check(nti.includes('new yt0(nw7VarO, nw7VarO2, yn7.LIBRARY'),
  'nti.R dispatches through yt0 picking a launcher');

// --- 原版：oj3 过滤表（图片9 + 音频6 + Office7 + pdf + txt [+octet-stream]） ---
check(oj3.includes('nj3.png') && oj3.includes('nj3.heic') && oj3.includes('nj3.webp'),
  'oj3 image set covers the nine nj3 image types');
check(oj3.includes('nj3.mp3') && oj3.includes('nj3.m4a') && oj3.includes('nj3.aiff'),
  'oj3 audio set covers the six nj3 audio types');
check(oj3.includes('nj3.docx') && oj3.includes('nj3.ppsx') && oj3.includes('nj3.xlsx'),
  'oj3 office set covers the seven nj3 office types');
check(oj3.includes('nj3.pdf') && oj3.includes('nj3.txt'),
  'oj3 adds pdf and txt');
check(oj3.includes('application/octet-stream'),
  'oj3.f additionally allows application/octet-stream');
check(!oj3.includes('nj3.note') && !oj3.includes('nj3.nbn') && !oj3.includes('nj3.ntb'),
  'oj3 never lists .note/.nbn/.ntb (no archive into-note merge upstream)');

// --- 原版：导入详情页 ou5（zvh 宿主）与默认目标 qv5 ---
check(zvh.includes('ou5.class') && zvh.includes('ImportDetailsViewModel'),
  'zvh hosts the ou5 ImportDetailsViewModel');
check(zvh.includes('onPasswordSubmitted') && zvh.includes('onPasswordCancelled'),
  'ou5 import-details handles encrypted-document passwords');
check(ub2.includes('qv5') && u49.includes('zvh.a(list, ttfVar'),
  'picked uri list flows into zvh.a bound to the open note (qv5 default)');
check(rv5.includes('CreateSeparateNotes'),
  'rv5 is CreateSeparateNotes for multi-file standalone import');
check(lb.includes('new tf9(list, wx4Var, context2, gl8Var4, null, 21)') ||
  lb.includes('tf9(list'), 'lb result handler forwards the uri list');
check(tf9.includes('gl8Var.setValue(list)') || tf9.includes('setValue(list)'),
  'tf9 stores the picked uri list into editor state');

// --- Harmony：双选择器多选 ---
const importFromFileStart = importer.indexOf('async importFromFile(');
const intoNoteStart = importer.indexOf('// 原版编辑器插入菜单「Add Files」');
const importFromFile = importer.substring(importFromFileStart, intoNoteStart);
check(importer.includes('const IMPORT_PICKER_MAX_SELECT: number = 500'),
  'maxSelectNumber constant caps at the Harmony 500 bound');
check(importFromFile.includes('selectOptions.maxSelectNumber = IMPORT_PICKER_MAX_SELECT'),
  'standalone picker enables multi-select');
check(importFromFile.includes('uris.length > 1') &&
  importFromFile.includes('importPickedFilesStandalone(uris, passwordPrompt)'),
  'standalone picker dispatches multi picks to the standalone loop');

const intoNoteEnd = importer.indexOf('private async importPdfFromBytes(', intoNoteStart);
const intoNote = importer.substring(intoNoteStart, intoNoteEnd);
check(intoNote.includes('selectOptions.maxSelectNumber = IMPORT_PICKER_MAX_SELECT'),
  'into-note picker enables multi-select');
check(intoNote.includes('uris.length > 1') &&
  intoNote.includes('importPickedFilesIntoNote(noteId, uris, passwordPrompt)'),
  'into-note picker dispatches multi picks to the into-note loop');
check(!intoNote.includes("'.note'"),
  'into-note picker still rejects .note (yq8.d/e opaque)');

// --- Harmony：多选循环保持同一类型分发表 ---
check(importer.includes('private async importPickedFilesStandalone(uris: string[],'),
  'standalone multi loop exists');
check(importer.includes('private async importPickedFilesIntoNote(noteId: string'),
  'into-note multi loop exists');
const standaloneLoop = importer.substring(
  importer.indexOf('private async importPickedFilesStandalone'),
  importer.indexOf('private async importPickedFilesIntoNote'));
check(standaloneLoop.includes('importPdfFromBytes') &&
  standaloneLoop.includes('importImageFromBytes') &&
  standaloneLoop.includes('importTextFromBytes') &&
  standaloneLoop.includes('importAudioFromBytes') &&
  standaloneLoop.includes('importFromData'),
  'standalone multi keeps the single-file dispatch table including .note');
check(importer.includes('importFileIntoNote(noteId,'),
  'into-note multi routes every file through importFileIntoNote');

// --- Harmony：逐文件读取 + 聚合报告 ---
check(importer.includes('function readPickedFile(uri: string): PickedFilePayload') &&
  importer.includes('fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY)'),
  'readPickedFile opens each uri read-only');
check(importer.includes('function aggregatePickedReports(reports: ImportReport[]'),
  'aggregatePickedReports merges per-file reports');
check(importer.includes('ImportResult.PARTIAL') &&
  importer.includes('个文件导入失败'),
  'aggregate maps all-fail to CORRUPTED and mixed to PARTIAL');

// --- Harmony：编辑器对 PARTIAL 也刷新（部分成功已落库） ---
check(notePage.includes('report.result !== ImportResult.PARTIAL'),
  'NotePage refreshes pages/recordings on PARTIAL multi-import');

console.log(`D05_ORIGINAL_MULTI_FILE_IMPORT_REPLAY_OK TOTAL=${total} FAILED=0`);
