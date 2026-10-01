// Phase 1421 — 文本域词/段界导航与 DELETE_PREV_CHAR 和弦移植
// 证据链：e0b.java（h3a/ya8 文本域 KeyEvent 分发）ctrl 支：
//   zs9.m/n/o/p = ofk.e(21/22/19/20) = DPAD_LEFT/RIGHT/UP/DOWN
//     → LEFT_WORD / RIGHT_WORD / PREV_PARAGRAPH / NEXT_PARAGRAPH；
//   ctrl+shift 支 → SELECT_LEFT_WORD / SELECT_RIGHT_WORD /
//     SELECT_PREV_PARAGRAPH / SELECT_NEXT_PARAGRAPH（shift=选区语义，
//     与 Shift+Home→SELECT_LINE_START 同一规则）；
//   zs9.d = ofk.e(36) = KEYCODE_H → DELETE_PREV_CHAR（Ctrl+H）。
// Harmony 键码：DPAD_UP/DOWN/LEFT/RIGHT = 2012..2015，H = 2024。
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

const e0b = fs.readFileSync(`${S}/e0b.java`, 'utf8');
const zs9 = fs.readFileSync(`${S}/zs9.java`, 'utf8');
const overlay = fs.readFileSync(`${H}/ets/ui/components/TextBlockOverlay.ets`, 'utf8');

// ---- 原版锚点 ----
check('zs9 方向键常量 m/n/o/p = 21/22/19/20',
  /m = ofk\.e\(21\)/.test(zs9) && /n = ofk\.e\(22\)/.test(zs9) &&
  /o = ofk\.e\(19\)/.test(zs9) && /p = ofk\.e\(20\)/.test(zs9));
check('zs9.d = ofk.e(36)（KEYCODE_H）', /d = ofk\.e\(36\)/.test(zs9));
check('e0b ctrl 支映射词/段导航',
  /pa8\.a\(jE2, zs9\.m\)\) \{\s*ra8Var = ra8\.LEFT_WORD/.test(e0b) &&
  /pa8\.a\(jE2, zs9\.n\)\) \{\s*ra8Var = ra8\.RIGHT_WORD/.test(e0b) &&
  /pa8\.a\(jE2, zs9\.o\)\) \{\s*ra8Var = ra8\.PREV_PARAGRAPH/.test(e0b) &&
  /pa8\.a\(jE2, zs9\.p\)\) \{\s*ra8Var = ra8\.NEXT_PARAGRAPH/.test(e0b));
check('e0b ctrl 支 Ctrl+H → DELETE_PREV_CHAR',
  /pa8\.a\(jE2, zs9\.d\)\)[\s\S]{0,90}DELETE_PREV_CHAR/.test(e0b));
check('e0b 存在 SELECT_*_WORD/PARAGRAPH 动作',
  e0b.includes('SELECT_LEFT_WORD') && e0b.includes('SELECT_RIGHT_WORD') &&
  e0b.includes('SELECT_PREV_PARAGRAPH') && e0b.includes('SELECT_NEXT_PARAGRAPH'));

// ---- Harmony 实现 ----
const handler = overlay.slice(overlay.indexOf('private onEditorKeyEvent'));
const seg = handler.slice(0, handler.indexOf('private collapseSelection'));
check('ctrl+shift 支四方向 → extendCaretSelection',
  /ctrl && shift && !alt[\s\S]{0,1200}2014[\s\S]{0,140}wordBoundaryLeft[\s\S]{0,200}2015[\s\S]{0,140}wordBoundaryRight[\s\S]{0,200}2012[\s\S]{0,140}paraBoundaryUp[\s\S]{0,200}2013[\s\S]{0,140}paraBoundaryDown/.test(seg));
check('纯 ctrl 支四方向 → caretPosition(词/段界)',
  /ctrl && !alt && !shift[\s\S]{0,1600}2014[\s\S]{0,140}wordBoundaryLeft[\s\S]{0,200}2015[\s\S]{0,140}wordBoundaryRight[\s\S]{0,200}2012[\s\S]{0,140}paraBoundaryUp[\s\S]{0,200}2013[\s\S]{0,140}paraBoundaryDown/.test(seg));
check('纯 ctrl 支 2024(H) → deletePrevChar',
  /2024[\s\S]{0,100}deletePrevChar\(\)/.test(seg));
check('词界近似实现存在（左=词首/右=词尾）',
  overlay.includes('private wordBoundaryLeft') &&
  overlay.includes('private wordBoundaryRight') &&
  overlay.includes('private isWordChar'));
check('段界实现存在（\\n 分隔）',
  overlay.includes('private paraBoundaryUp') &&
  overlay.includes('private paraBoundaryDown') &&
  overlay.includes("lastIndexOf('\\n'") && overlay.includes("indexOf('\\n'"));
check('选区扩展保留锚定/移动端语义',
  /extendCaretSelection[\s\S]{0,400}setTextSelection\(anchor, p\)/.test(overlay) &&
  overlay.includes('this.caretSelectionStart = anchor'));
check('deletePrevChar 走 draftText+adjustCharRunsForEdit+onDraftChange',
  /private deletePrevChar[\s\S]{0,800}adjustCharRunsForEdit[\s\S]{0,80}onDraftChange/.test(overlay));

console.log(`\nD02_ORIGINAL_TEXT_KBD_NAV_REPLAY_OK TOTAL=${checks.length} FAILED=0`);
