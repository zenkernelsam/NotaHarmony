// D02 原版导入详情页 arrange 模式移植 — Phase 715（ADR-0663）。
// 原版 w8:155 头部 Arrange↔Done 切换 + te4 行内 move_up/move_down；
// 重排序随 ImportPlan.orderedUris 回传 dispatchImportPlan。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');
const JADX = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const w8 = read(`${JADX}/sources/defpackage/w8.java`);
const te4 = read(`${JADX}/sources/defpackage/te4.java`);
const strings = read(`${JADX}/resources/res/values/strings.xml`);
const sheet = read('note/src/main/ets/ui/components/ImportDetailsSheet.ets');
const importer = read('note/src/main/ets/data/NoteImporter.ets');
const en = read('note/src/main/resources/base/element/string.json');
const zh = read('note/src/main/resources/zh_CN/element/string.json');

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 原版证据 ---
check(strings.includes('ui_fileimport__arrange') &&
  strings.includes('ui_fileimport__move_up') &&
  strings.includes('ui_fileimport__move_down'), '原版 arrange/move 字符串');
check(/arrange.*done|done.*arrange/si.test(w8),
  'w8 Arrange↔Done 切换按钮');
check(te4.includes('ui_fileimport__move_up') &&
  te4.includes('ui_fileimport__move_down'), 'te4 行内 move_up/move_down');

// --- Harmony 移植 ---
check(sheet.includes('@State arranging: boolean'),
  'arranging 状态');
check(sheet.includes('@State orderedFiles: ImportFileDescriptor[]'),
  'orderedFiles 可排序副本');
check(/private moveFile\(index: number, delta: number\)/.test(sheet),
  'moveFile 交换助手');
check(/files\[index\] = files\[target\]/.test(sheet) &&
  /drafts\[index\] = drafts\[target\]/.test(sheet),
  'moveFile 同步交换文件与题草稿');
check(sheet.includes("$r('app.string.import_move_up')") &&
  sheet.includes("$r('app.string.import_move_down')"),
  '行内 ↑/↓ 无障碍标签');
check(sheet.includes('$r(\'app.string.import_arrange\')') &&
  sheet.includes('$r(\'app.string.done\')'),
  '头部 Arrange/Done 切换');
check(/orderedFiles\.length > 1/.test(sheet), 'arrange 仅多文件可见');
check(sheet.includes('orderedUris: this.orderedFiles.map'),
  'confirm 回传 orderedUris');
check(/if \(!this\.arranging &&\s*\n\s*this\.destination === ImportDestination\.SEPARATE_NOTES\)/.test(sheet),
  'arrange 态隐藏逐文件题输入');

// --- 分发层 ---
check(importer.includes('orderedUris?: string[]'),
  'ImportPlan.orderedUris 可选字段');
check(/plan\.orderedUris !== undefined &&\s*\n\s*plan\.orderedUris\.length === uris\.length/.test(importer),
  'dispatch 长度校验防越界');
check(/importPickedFilesIntoNote\(target, effective/.test(importer) &&
  /importFilesIntoSingleNewNote\(effective/.test(importer) &&
  /importPickedFilesStandalone\(effective/.test(importer),
  '三分支均走重排序');

// --- 字符串（双 locale）---
for (const k of ['import_arrange', 'import_move_up', 'import_move_down']) {
  check(en.includes(`"name": "${k}"`), `en ${k}`);
  check(zh.includes(`"name": "${k}"`), `zh ${k}`);
}

// --- ADR/证据 ---
check(read('docs/migration/adr/ADR-0663-original-import-arrange-mode.md')
  .includes('w8'), 'ADR-0663 声明 w8/te4 语义');
check(read('docs/migration/evidence/original-import-arrange-mode-jadx-2026-09-26.md')
  .includes('move_up'), '证据文档记录行内移动');

console.log(`D02_ORIGINAL_IMPORT_ARRANGE_MODE_OK TOTAL=${total} FAILED=0`);
