// Phase 682 — 原版 u49/mw3 空笔记动作面：笔记无元素时底部四动作卡
//   Record → Import → Scan(ac4.a0 门) → Capture（相机回调存在才显示）。
// 原版证据（decompiled_1.0.3/sources/defpackage）：
//   mw3.java     case0：p40.b 四卡——
//                record_mic_outline + empty_note__record_audio（合并
//                function0/function1 为录音入口）；
//                import_new_note + empty_note__import_file（function2）；
//                zA 门内 docscan + empty_note__scan（function3）；
//                function4 != null 时 capture_screen_content +
//                empty_note__capture_and_add。
//   u49.java     zA = lc4.a(ac4.a0) → p40.a(0,…,function18,function7,…,
//                function16,function0A,zA)；empty_note__scan_failed 失败串。
//   strings.xml  feature_note__empty_note__{capture_and_add,import_file,
//                record_audio,scan,scan_failed}。
// Harmony（NotePage）：page_element_snapshot 元素总数为 0 时画布底部
//   四 EmptyNoteActionChip（CreateActionChip 文本风格，图标差异登记
//   ADR-0649）；Scan 卡以 VisionKit DocScan 可用性等价 ac4.a0 门；
//   Capture 卡对齐「回调存在即显示」——Harmony 编辑器相机入口恒可用；
//   Scan 结果经 NoteImporter.importScannedIntoNote 并入当前笔记
//   （qv5 AddToExistingNote 语义），与资料库扫描建新笔记区分。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const mw3 = fs.readFileSync(`${originalRoot}sources/defpackage/mw3.java`, 'utf8');
const u49 = fs.readFileSync(`${originalRoot}sources/defpackage/u49.java`, 'utf8');
const stringsXml = fs.readFileSync(`${originalRoot}resources/res/values/strings.xml`, 'utf8');

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8');
const importer = fs.readFileSync('note/src/main/ets/data/NoteImporter.ets', 'utf8');
const en = fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zh = fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 原版证据钉 ---
check(mw3.includes('ui_designsystem__record_mic_outline') &&
  mw3.includes('feature_note__empty_note__record_audio'),
  'mw3 Record 卡（record_mic_outline + record_audio）');
check(mw3.includes('ui_designsystem__import_new_note') &&
  mw3.includes('feature_note__empty_note__import_file'),
  'mw3 Import 卡（import_new_note + import_file）');
check(mw3.includes('ui_fileimport__docscan') &&
  mw3.includes('feature_note__empty_note__scan'), 'mw3 Scan 卡（docscan + scan）');
check(mw3.includes('ui_designsystem__capture_screen_content') &&
  mw3.includes('feature_note__empty_note__capture_and_add'),
  'mw3 Capture 卡（capture_screen_content + capture_and_add）');
check(mw3.split('p40.b(').length - 1 >= 4, 'mw3 四个 p40.b 动作卡');
check(u49.includes('final boolean zA = lc4.a(ac4.a0);') &&
  u49.includes('p40.a(') && u49.includes(', zA)'),
  'u49 Scan 卡 ac4.a0 门 → p40.a(…,zA)');
check(u49.includes('feature_note__empty_note__scan_failed'), 'u49 scan_failed 串');
for (const key of ['capture_and_add', 'import_file', 'record_audio', 'scan',
  'scan_failed']) {
  check(stringsXml.includes(`feature_note__empty_note__${key}`),
    `original string empty_note__${key}`);
}

// --- Harmony 动作面 ---
check(page.includes('@State emptyNoteActions: boolean = false'),
  'emptyNoteActions state');
check(page.includes('refreshEmptyNoteActions') &&
  page.includes('getPageElementCounts(this.noteId)') &&
  page.includes('total === 0'),
  '空笔记判定：page_element_snapshot 元素总数为 0');
check(page.includes('Stack({ alignContent: Alignment.Bottom })'),
  '画布 Stack 底对齐承载动作卡');
check(page.includes("EmptyNoteActionChip($r('app.string.empty_note_record')") &&
  page.includes('this.startRecording()'), 'Record 卡 → startRecording');
check(page.includes("EmptyNoteActionChip($r('app.string.empty_note_import')") &&
  page.includes('this.importFileIntoCurrentNote()'),
  'Import 卡 → importFileIntoCurrentNote');
const scanChip = page.slice(page.indexOf("empty_note_scan')"));
check(page.includes('if (this.docScanAvailable)') &&
  scanChip.indexOf('docScanOpen = true') < scanChip.indexOf('empty_note_capture_add'),
  'Scan 卡 docScanAvailable 门 + docScanOpen');
check(page.includes("EmptyNoteActionChip($r('app.string.empty_note_capture_add')") &&
  page.includes('this.cameraCaptureSignal++'),
  'Capture 卡 → cameraCaptureSignal（ingress lease）');

// --- Harmony 扫描管线 ---
check(page.includes("canIUse('SystemCapability.AI.Component.DocScan')"),
  'DocScan 能力探测 = ac4.a0 等价门');
check(page.includes('bindContentCover(this.docScanOpen') &&
  page.includes('DocScanCover') && page.includes('DocumentScanner({'),
  'DocumentScanner 全屏 cover');
check(page.includes('config.supportType = [DocType.DOC]') &&
  page.includes('config.saveOptions = [SaveOption.PDF]') &&
  page.includes('config.maxShotCount = ORIGINAL_DOC_SCAN_MAX_PAGES') &&
  page.includes('config.isShareable = false'),
  'DocScan 配置与 P680 资料库扫描同一契约');
check(page.includes('code !== 200') && page.includes('code !== -1') &&
  page.includes("empty_note_scan_failed"),
  'onDocScanResult 200/–1/失败 三分支');
check(page.includes('async scanIntoCurrentNote(uris: string[])') &&
  page.includes('importScannedIntoNote'),
  '扫描产物并入当前笔记（非新建）');
check(importer.includes('async importScannedIntoNote(noteId: string, uris: string[]') &&
  importer.includes('importPickedFilesIntoNote(noteId, uris'),
  'importScannedIntoNote → importPickedFilesIntoNote（qv5 语义）');

// --- 刷新钩子 ---
check(page.includes('this.refreshEmptyNoteActions();\n      const loadedBackground'),
  '初始载入后评估');
check(page.includes('this.pageContentVersion++;\n      this.refreshEmptyNoteActions();'),
  '导入成功后重评估');
check(page.includes('this.pageContentVersion++;\n              // 可撤销变更可能改写元素集合'),
  '可撤销变更后重评估');

// --- 资源串 ---
for (const key of ['empty_note_capture_add', 'empty_note_import',
  'empty_note_record', 'empty_note_scan', 'empty_note_scan_failed']) {
  check(en.includes(`"name": "${key}"`), `en string ${key}`);
  check(zh.includes(`"name": "${key}"`), `zh string ${key}`);
}
check(en.includes('"Capture and add"'), 'en capture_and_add = 原版值');

console.log(`D02_ORIGINAL_EMPTY_NOTE_ACTIONS_OK TOTAL=${n} FAILED=0`);
