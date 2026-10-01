// Phase 1422 — 键盘快捷键帮助表（txm.a → KeyboardShortcutHelper）移植
// 证据链：txm.a = cma.a + vla.c + f3b.a + syh.a 合并为
// KeyboardShortcutGroup 树（lag{labelRes,groupRes,chords}，
// 每 qa8 → KeyboardShortcutInfo 一行）；Ctrl+/ = yla(open_help) →
// qw6 路由 → 系统 requestShowKeyboardShortcuts。f3b.a 为空（死支）。
// Navigation 组序 = vla.a LinkedHashMap 保序（N/,L//）+ new_window + dismiss；
// Text Editing 组序 = syh.a et9.z0 保序（17 动作 18 行——REDO 两和弦）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/defpackage';
const H = 'C:/HarmonyProject/NotaHarmony/note/src/main';

const checks = [];
const check = (name, cond) => {
  assert.equal(cond, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const txm = fs.readFileSync(`${S}/txm.java`, 'utf8');
const cma = fs.readFileSync(`${S}/cma.java`, 'utf8');
const vla = fs.readFileSync(`${S}/vla.java`, 'utf8');
const syh = fs.readFileSync(`${S}/syh.java`, 'utf8');
const ra8 = fs.readFileSync(`${S}/ra8.java`, 'utf8');
const chords = fs.readFileSync(`${H}/ets/data/OriginalKeyboardChords.ets`, 'utf8');
const notePage = fs.readFileSync(`${H}/ets/ui/editor/NotePage.ets`, 'utf8');
const library = fs.readFileSync(`${H}/ets/ui/library/LibraryPage.ets`, 'utf8');
const enStr = fs.readFileSync(`${H}/resources/base/element/string.json`, 'utf8');
const zhStr = fs.readFileSync(`${H}/resources/zh_CN/element/string.json`, 'utf8');

// ---- 原版锚点 ----
check('txm.a 合并 cma+vla.c+f3b+syh 为 KeyboardShortcutGroup',
  txm.includes('cma.a, vla.c)') && txm.includes('f3b.a), syh.a') &&
  txm.includes('new KeyboardShortcutGroup(string, arrayList3)') &&
  txm.includes('new KeyboardShortcutInfo(string2, i, i2)'));
check('cma.a = vla.a 保序 + dismiss_deselect qa8(111,14)',
  cma.includes('R.string.app__kbd_shortcut_dismiss_deselect') &&
  cma.includes('new qa8(111, 14)') &&
  cma.includes('R.string.app__kbd_shortcut_group_navigation'));
check('vla.a = N/,L/Slash 导航和弦 + vla.c=new_window',
  vla.includes('new qa8(42, 12), xla.a') && vla.includes('new qa8(55, 12), zla.a') &&
  vla.includes('new qa8(40, 12), wla.a') && vla.includes('new qa8(76, 12), yla.a') &&
  vla.includes('R.string.app__kbd_shortcut_new_window'));
check('syh.a 文本组 17 动作（REDO 双和弦）',
  syh.includes('R.string.ui_text__kbd_shortcut_group_text_editing') &&
  syh.includes('new qa8(54, 4), new qa8(53, 12)') &&
  ra8.includes('ui_text__kbd_shortcut_checkbox_list') &&
  ra8.includes('ui_text__kbd_shortcut_deselect'));

// ---- 数据表 ----
check('ORIGIN_KBD_HELP_GROUPS 两组注册',
  chords.includes('app__kbd_shortcut_group_navigation') &&
  chords.includes('ui_text__kbd_shortcut_group_text_editing'));
check('Navigation 组 6 条（vla.a 序 + new_window + dismiss）',
  /kbd_shortcut_new_note'.*Ctrl\+N/.test(chords) &&
  /kbd_shortcut_open_settings'.*Ctrl\+,/.test(chords) &&
  /kbd_shortcut_back_to_library'.*Ctrl\+L/.test(chords) &&
  /kbd_shortcut_open_help'.*Ctrl\+\//.test(chords) &&
  /kbd_shortcut_new_window'.*Ctrl\+Shift\+N/.test(chords) &&
  /kbd_shortcut_dismiss_deselect'.*Esc/.test(chords));
check('Text Editing 组 17 条全注册（含 REDO 双行/Deselect Ctrl+\\\\）',
  /kbd_shortcut_copy'.*Ctrl\+C/.test(chords) &&
  /kbd_shortcut_paste'.*Ctrl\+V/.test(chords) &&
  /kbd_shortcut_cut'.*Ctrl\+X/.test(chords) &&
  /kbd_shortcut_select_all'.*Ctrl\+A/.test(chords) &&
  /kbd_shortcut_undo'.*Ctrl\+Z/.test(chords) &&
  /kbd_shortcut_redo'.*Ctrl\+Shift\+Z.*Ctrl\+Y/.test(chords) &&
  /kbd_shortcut_bold'.*Ctrl\+B/.test(chords) &&
  /kbd_shortcut_italic'.*Ctrl\+I/.test(chords) &&
  /kbd_shortcut_underline'.*Ctrl\+U/.test(chords) &&
  /kbd_shortcut_bullet_list'.*Ctrl\+Shift\+B/.test(chords) &&
  /kbd_shortcut_numbered_list'.*Ctrl\+Shift\+L/.test(chords) &&
  /kbd_shortcut_checkbox_list'.*Ctrl\+Shift\+C/.test(chords) &&
  /kbd_shortcut_increase_font_size'.*Ctrl\+Alt/.test(chords) &&
  /kbd_shortcut_decrease_font_size'.*Ctrl\+Alt/.test(chords) &&
  /kbd_shortcut_text_start'.*Alt/.test(chords) &&
  /kbd_shortcut_text_end'.*Alt/.test(chords) &&
  /kbd_shortcut_deselect'.*Ctrl\+/.test(chords));

// ---- 双语字符串 ----
const needEn = [
  'app__kbd_shortcut_group_navigation', 'app__kbd_shortcut_new_note',
  'app__kbd_shortcut_open_settings', 'app__kbd_shortcut_back_to_library',
  'app__kbd_shortcut_open_help', 'app__kbd_shortcut_new_window',
  'app__kbd_shortcut_dismiss_deselect',
  'ui_text__kbd_shortcut_group_text_editing', 'ui_text__kbd_shortcut_copy',
  'ui_text__kbd_shortcut_paste', 'ui_text__kbd_shortcut_cut',
  'ui_text__kbd_shortcut_select_all', 'ui_text__kbd_shortcut_undo',
  'ui_text__kbd_shortcut_redo', 'ui_text__kbd_shortcut_bold',
  'ui_text__kbd_shortcut_italic', 'ui_text__kbd_shortcut_underline',
  'ui_text__kbd_shortcut_bullet_list', 'ui_text__kbd_shortcut_numbered_list',
  'ui_text__kbd_shortcut_checkbox_list', 'ui_text__kbd_shortcut_increase_font_size',
  'ui_text__kbd_shortcut_decrease_font_size', 'ui_text__kbd_shortcut_text_start',
  'ui_text__kbd_shortcut_text_end', 'ui_text__kbd_shortcut_deselect',
];
check('en 侧 25 键齐备',
  needEn.every((k) => enStr.includes(`"name": "${k}"`)));
check('zh 侧 25 键齐备',
  needEn.every((k) => zhStr.includes(`"name": "${k}"`)));

// ---- NotePage 接线 ----
check('NotePage Ctrl+/ → showShortcutsHelp',
  /ORIGIN_CHORD_OPEN_HELP[\s\S]{0,200}showShortcutsHelp = true/.test(notePage) &&
  notePage.includes('@State showShortcutsHelp: boolean'));
check('NotePage bindSheet + builder',
  /bindSheet\(this\.showShortcutsHelp, this\.buildShortcutsHelpSheet\(\)/.test(notePage) &&
  notePage.includes('buildShortcutsHelpSheet()'));
check('NotePage ESC 链含 showShortcutsHelp 早退',
  /ORIGIN_CHORD_DISMISS[\s\S]{0,400}showShortcutsHelp = false/.test(notePage));
check('NotePage 渲染 ORIGIN_KBD_HELP_GROUPS',
  notePage.includes('ForEach(ORIGIN_KBD_HELP_GROUPS'));

// ---- LibraryPage 接线（活动级路由等价）----
check('LibraryPage Ctrl+/ → showShortcutsHelp',
  /ORIGIN_CHORD_OPEN_HELP[\s\S]{0,200}showShortcutsHelp = true/.test(library) &&
  library.includes('@State showShortcutsHelp: boolean'));
check('LibraryPage bindSheet + ShortcutsHelpSheet',
  /bindSheet\(this\.showShortcutsHelp, this\.ShortcutsHelpSheet\(\)/.test(library) &&
  library.includes('ShortcutsHelpSheet()'));
check('LibraryPage ESC 链含 showShortcutsHelp 早退',
  /ORIGIN_CHORD_DISMISS[\s\S]{0,300}showShortcutsHelp = false/.test(library));

console.log(`\nD02_ORIGINAL_KBD_HELP_SHEET_REPLAY_OK TOTAL=${checks.length} FAILED=0`);
