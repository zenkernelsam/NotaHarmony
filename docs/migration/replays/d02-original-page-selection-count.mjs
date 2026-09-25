// D02 原版页选计数标签 + 导入sheet 默认笔记题 — Phase 716（ADR-0664）。
// p7j:663/951 ui_pageselection__x_of_y_selected 工具条计数；
// data_library_state__default_note_title="New Note" 取代散落的
// 'Untitled' 字面量。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');
const JADX = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const p7j = read(`${JADX}/sources/defpackage/p7j.java`);
const id7 = read(`${JADX}/sources/defpackage/id7.java`);
const strings = read(`${JADX}/resources/res/values/strings.xml`);
const panel = read('note/src/main/ets/ui/editor/PageOverviewPanel.ets');
const sheet = read('note/src/main/ets/ui/components/ImportDetailsSheet.ets');
const en = read('note/src/main/resources/base/element/string.json');
const zh = read('note/src/main/resources/zh_CN/element/string.json');

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 原版证据 ---
check(strings.includes('ui_pageselection__x_of_y_selected'),
  '原版 x_of_y_selected 字符串');
check(/x_of_y_selected.*Integer\.valueOf\(i10\), Integer\.valueOf\(list\.size\(\)\)/s.test(p7j) ||
  (p7j.match(/x_of_y_selected/g) || []).length === 2,
  'p7j 两处渲染 选中/总数 计数');
check(/default_note_title">New Note</.test(strings),
  '原版默认笔记题 = "New Note"');
check(id7.includes('data_library_state__default_note_title'),
  'id7 建篇默认题走资源串');

// --- Harmony 移植 ---
check(panel.includes('pages_x_of_y_selected'),
  'PageOverviewPanel 计数标签');
check(/pages_x_of_y_selected',\s*\n?\s*this\.selectedPageIds\.length,\s*\n?\s*this\.visibleItems\(\)\.length/.test(panel),
  '计数 = selectedPageIds/visibleItems');
check(panel.includes('layoutWeight(1)'), '选择条计数旁 chips 滚动布局');

// --- 默认题统一 ---
check(!sheet.includes("'Untitled'"), 'ImportDetailsSheet 无 Untitled 字面量');
check(sheet.includes("$r('app.string.untitled_note')"),
  'ImportDetailsSheet 走 untitled_note 资源');
check(/"untitled_note"[\s\S]*?"value": "New Note"/.test(en),
  'en untitled_note = New Note');
check(/"untitled_note", "value": "新笔记"/.test(zh),
  'zh untitled_note = 新笔记');

// --- 字符串（双 locale）---
check(en.includes('"name": "pages_x_of_y_selected"'), 'en 计数串');
check(zh.includes('"name": "pages_x_of_y_selected"'), 'zh 计数串');
check(en.includes('"%d of %d selected"'), 'en 计数格式 %d/%d');

// --- ADR/证据 ---
check(read('docs/migration/adr/ADR-0664-original-page-selection-count-default-title.md')
  .includes('p7j'), 'ADR-0664 声明 p7j 计数语义');
check(read('docs/migration/evidence/original-page-selection-count-jadx-2026-09-26.md')
  .includes('New Note'), '证据文档记录默认题');

console.log(`D02_ORIGINAL_PAGE_SELECTION_COUNT_OK TOTAL=${total} FAILED=0`);
