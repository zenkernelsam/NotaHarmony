// D02 ui_text__ 族尾部收口 — Phase 719（ADR-0667）。
// 可移植项：fie add_text 工具项标签、bn5:127 链接 sheet 标题择一
// （en5.c→Edit hyperlink 否则 Insert hyperlink）、i8j 语言菜单
// programming_language 标题。边界登记：kbd_shortcut_*（Android
// onProvideKeyboardShortcuts 系统快捷键表，HarmonyOS 无对位）、
// hr4/ir4 动态样式名标签（模型无具名样式字段）、whh 字号下拉
// 语义（Harmony 为步进器，无 chevron 节点）。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');
const JADX = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const fie = read(`${JADX}/sources/defpackage/fie.java`);
const bn5 = read(`${JADX}/sources/defpackage/bn5.java`);
const i8j = read(`${JADX}/sources/defpackage/i8j.java`);
const hke = read(`${JADX}/sources/defpackage/hke.java`);
const kmi = read(`${JADX}/sources/defpackage/kmi.java`);
const ir4 = read(`${JADX}/sources/defpackage/ir4.java`);
const overlay = read('note/src/main/ets/ui/components/TextBlockOverlay.ets');
const toolbar = read('note/src/main/ets/ui/editor/EditorToolbar.ets');
const settings = read('note/src/main/ets/ui/editor/ToolboxSettingsDialog.ets');
const en = read('note/src/main/resources/base/element/string.json');
const zh = read('note/src/main/resources/zh_CN/element/string.json');

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 原版证据 ---
check(fie.includes('ui_text__add_text'), 'fie 工具项标签 add_text');
check(/c \? R\.string\.ui_text__edit_hyperlink : R\.string\.ui_text__insert_hyperlink/
  .test(bn5), 'bn5 链接对话框标题按 en5.c 择一');
check(i8j.includes('ui_text__programming_language'), 'i8j 语言菜单标题');
check(hke.includes('kbd_shortcut_group_text_editing') && hke.includes('wl6.'),
  'hke 快捷键注册表（wl6 键位×12）');
check(kmi.includes('KeyboardShortcutGroup'),
  'kmi 产出系统 KeyboardShortcutGroup（平台快捷键帮助）');
check(ir4.includes('ui_text__undefined_format'), 'ir4 未定义样式兜底 "Format"');

// --- Harmony 移植 ---
check(settings.includes("$r('app.string.add_text')") &&
  toolbar.includes("$r('app.string.add_text')"),
  'add_text 落地 toolTypeLabel 默认 + 工具菜单项');
check(overlay.includes('linkSheetIsEdit') &&
  overlay.includes("$r('app.string.edit_hyperlink')") &&
  overlay.includes("$r('app.string.insert_hyperlink')"),
  '链接 sheet 标题 insert/edit 择一');
check(/linkUrlDraft = this\.linkUrlAt\(s, e\);[\s\S]{0,200}linkSheetIsEdit = this\.linkUrlDraft\.length > 0/
  .test(overlay), 'linkSheetIsEdit 由既有链接判定');
check(overlay.includes("$r('app.string.programming_language')") &&
  /bindMenu\(this\.buildCodeLanguageMenu\(\),[\s\S]{0,80}title:/.test(overlay),
  '语言菜单 bindMenu title');
for (const k of ['add_text', 'insert_hyperlink', 'edit_hyperlink',
  'programming_language', 'fontsize']) {
  check(en.includes(`"${k}"`), `en ${k}`);
  check(zh.includes(`"${k}"`), `zh ${k}`);
}
check(en.includes('"add_text", "value": "Add Text"'), 'en add_text 值对齐原版');
check(en.includes('"edit_hyperlink", "value": "Edit hyperlink"') &&
  en.includes('"insert_hyperlink", "value": "Insert hyperlink"'),
  'en hyperlink 双标题对齐原版');

console.log(`TOTAL=${total} FAILED=0`);
