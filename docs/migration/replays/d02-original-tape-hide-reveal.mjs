// Phase 583 — original global Hide/Reveal Tapes toggle.
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   o94.java case14 — the tape tool's settings row flips between
//     ui_tools__reveal_tapes_action (hidden state) and
//     ui_tools__hide_tapes_action (revealed state).
//   jg9.n — the UI-state boolean printed as "tapesRevealed=..."; uf0 case4
//     computes it as ANY visible tape id being inside the revealed set.
//   oh9 = OnToggleTapesRevealed → ti9:360-380 reads the visible tape id set,
//     tests whether ALL visible tapes are already revealed, and dispatches
//     np0(z, set, 5); np0 case5 does ys2.J union (reveal) or ys2.H subtract
//     (hide) on the revealed-id register.
//   yd9.j = NoteSessionState.revealedTape — session-scoped, never persisted.
//   i16:151-175 — the tape pattern layer (ife.STRIPES / explicit pattern) is
//     suppressed (ifeVar=null) unless the element id is in the revealed set;
//     the plain stroke body still renders through the baked mwd.o path.
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const PAINTER = 'note/src/main/ets/rendering/StrokeCanvasPainter.ets';
const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const PAGE = 'note/src/main/ets/ui/editor/NotePage.ets';
const STRINGS = 'note/src/main/resources/base/element/string.json';
const STRINGS_ZH = 'note/src/main/resources/zh_CN/element/string.json';

const painter = readFileSync(PAINTER, 'utf8');
const canvas = readFileSync(CANVAS, 'utf8');
const page = readFileSync(PAGE, 'utf8');
const strings = readFileSync(STRINGS, 'utf8');
const stringsZh = readFileSync(STRINGS_ZH, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- Render gate (i16 z3 → ifeVar=null analog) ---
check(painter.includes('revealedTapeIds: Set<string>'),
  'painter holds the session revealed-tape id set');
check(/renderSpec\.tapePattern !== undefined\s*&&\s*!this\.revealedTapeIds\.has\(stroke\.id\)/
  .test(painter), 'tape pattern suppressed unless id is revealed');
check(painter.indexOf('renderCenterPath(stroke, rc)') <
  painter.indexOf('renderTapePattern(stroke, rc, viewportZoom)'),
  'plain stroke body still renders beneath the gated pattern');

// --- Session state + toggle semantics (yd9.j / oh9 → np0 case5) ---
check(canvas.includes('revealedTapeIds: Set<string> = new Set()'),
  'canvas owns the session-scoped revealed set (not persisted)');
check(canvas.includes('this.strokePainter.revealedTapeIds = this.revealedTapeIds'),
  'painter shares the canvas revealed set');
check(canvas.includes('tapeToggleSignal'), 'toggle signal prop wired');
const toggle = canvas.slice(canvas.indexOf('private toggleTapesReveal'));
check(toggle.includes('tapeIds.length === 0'), 'ti9:362 parity — no tapes → no-op');
check(toggle.includes('revealedTapeIds.has(id)') &&
  toggle.includes('revealedTapeIds.delete(id)') &&
  toggle.includes('revealedTapeIds.add(id)'),
  'all-revealed → subtract (ys2.H), else union (ys2.J)');
check(toggle.includes('renderFrame(true)'), 'toggle triggers a redraw');
check(canvas.includes('emitTapeRevealState'), 'label state emitted to host');
check(canvas.indexOf('emitTapeRevealState') >= 0 &&
  canvas.includes('onTapeRevealStateChanged(tapeIds.length, anyRevealed)'),
  'uf0 case4 parity — (tapeCount, anyRevealed) pair emitted');

// --- Menu surface + label semantics (o94 case14 / jg9.n) ---
check(page.includes('tapeToggleSignal++'), 'menu action bumps the toggle signal');
check(page.includes('pageTapeCount > 0'),
  'tape row only surfaces when the page has tapes');
check(/anyTapeRevealed \?\s*\n?\s*\$r\('app\.string\.hide_tapes'\)\s*:\s*\$r\('app\.string\.reveal_tapes'\)/
  .test(page), 'label flips hide↔reveal by anyTapeRevealed (uf0 ANY semantics)');
check(page.includes('onTapeRevealStateChanged'),
  'canvas reveal-state callback consumed by NotePage');
check(page.includes('tapeToggleSignal: this.tapeToggleSignal'),
  'toggle signal passed into the canvas');

// --- Strings ---
check(strings.includes('"name": "hide_tapes"') && strings.includes('"value": "Hide Tapes"'),
  'EN hide_tapes string');
check(strings.includes('"name": "reveal_tapes"') && strings.includes('"value": "Reveal Tapes"'),
  'EN reveal_tapes string');
check(stringsZh.includes('"name": "hide_tapes"') && stringsZh.includes('"name": "reveal_tapes"'),
  'zh_CN hide/reveal strings');

console.log(`D02_ORIGINAL_TAPE_HIDE_REVEAL_OK TOTAL=${n} FAILED=0`);
