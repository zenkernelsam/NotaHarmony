// Phase 695 — 原版文本编辑键盘快捷键（hke/k09/wl6）移植静态 Replay。
// 证据：decompiled_1.0.3 sources/defpackage/{hke,k09,wl6,hp8}.java
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

let total = 0;
const check = (cond, label) => { total++; assert.ok(cond, label); };
const read = (p) => readFileSync(p, 'utf8');
const SRC = process.env.NOTA_SRC ?? 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';

// ---------- 原版证据钉 ----------
const hke = read(`${SRC}/sources/defpackage/hke.java`);
check(hke.includes('wl6.COPY') && hke.includes('wl6.PASTE') &&
  hke.includes('wl6.CUT') && hke.includes('wl6.SELECT_ALL'),
  'hke: clipboard + select-all shortcuts');
check(hke.includes('wl6.UNDO') && hke.includes('wl6.REDO'),
  'hke: undo/redo shortcuts');
check(hke.includes('wl6.TOGGLE_BOLD') && hke.includes('wl6.TOGGLE_ITALIC') &&
  hke.includes('wl6.TOGGLE_UNDERLINE'),
  'hke: B/I/U toggle shortcuts');
check(hke.includes('wl6.HOME') && hke.includes('wl6.END') &&
  hke.includes('wl6.DESELECT'),
  'hke: HOME/END + DESELECT');
check(hke.includes('ui_text__kbd_shortcut_group_text_editing'),
  'hke: Text Editing shortcut group');

const k09 = read(`${SRC}/sources/defpackage/k09.java`);
check(k09.includes('keyEvent.isCtrlPressed()'),
  'k09: ctrl-modified key dispatch');
check(k09.includes('wl6.LEFT_WORD') || k09.includes('wl6.SELECT_LEFT_WORD'),
  'k09: word/selection navigation actions exist');

const stringsXml = read(`${SRC}/resources/res/values/strings.xml`);
check(stringsXml.includes('ui_text__kbd_shortcut_group_text_editing">Text Editing') &&
  stringsXml.includes('ui_text__kbd_shortcut_bold">Bold') &&
  stringsXml.includes('ui_text__kbd_shortcut_text_start">Go to Start of Text') &&
  stringsXml.includes('ui_text__kbd_shortcut_text_end">Go to End of Text') &&
  stringsXml.includes('ui_text__kbd_shortcut_deselect">Deselect'),
  'original kbd shortcut strings');

// ---------- Harmony 实现钉 ----------
const overlay = read('note/src/main/ets/ui/components/TextBlockOverlay.ets');
check(overlay.includes('.onKeyEvent((event: KeyEvent): boolean =>'),
  'overlay: onKeyEvent attached to TextArea');
check(overlay.includes('private onEditorKeyEvent(event: KeyEvent): boolean'),
  'overlay: onEditorKeyEvent handler');
check(overlay.includes('event.type !== KeyType.Down'),
  'overlay: only KeyType.Down handled');
check(overlay.includes("getModifierKeyState(['ctrl'])") ||
  overlay.includes("getModifierKeyState(['Ctrl'])"),
  'overlay: ctrl modifier detection');
check(overlay.includes('event.keyCode === 2018') &&
  overlay.includes("this.toggleCharStyle('bold')"),
  'overlay: Ctrl+B (2018) -> bold');
check(overlay.includes('event.keyCode === 2025') &&
  overlay.includes("this.toggleCharStyle('italic')"),
  'overlay: Ctrl+I (2025) -> italic');
check(overlay.includes('event.keyCode === 2037') &&
  overlay.includes("this.toggleCharStyle('underline')"),
  'overlay: Ctrl+U (2037) -> underline');
check(overlay.includes('event.keyCode === 2017') &&
  overlay.includes('this.controller.setTextSelection(0, this.draftText.length)'),
  'overlay: Ctrl+A (2017) -> select all');
check(overlay.includes('event.keyCode === 2081') &&
  overlay.includes('this.controller.caretPosition(0)'),
  'overlay: Ctrl+Home (2081) -> text start');
check(overlay.includes('event.keyCode === 2082') &&
  overlay.includes('this.controller.caretPosition(this.draftText.length)'),
  'overlay: Ctrl+End (2082) -> text end');
check(overlay.includes('event.keyCode === 2020') &&
  overlay.includes('event.keyCode === 2070') &&
  overlay.includes('this.collapseSelection()'),
  'overlay: Ctrl+D (2020) + Esc (2070) -> deselect');
check(overlay.includes('private collapseSelection(): void') &&
  overlay.includes('this.controller.caretPosition(this.caretOffset)'),
  'overlay: collapseSelection folds selection to caret');
check(overlay.includes('this.photoImportLeaseActive'),
  'overlay: lease guard on key handler');

console.log(`D02_ORIGINAL_TEXT_KEYMAP_REPLAY_OK TOTAL=${total} FAILED=0`);
