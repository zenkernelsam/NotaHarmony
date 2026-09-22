// Phase 585 — original tape pattern picker (mh9 → t7f → nh9).
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   mh9 = OnShowTapePatterns → ti9:352 → bi9 variant3 → t7f sheet content.
//   lfe.a:10 — picker lists the 9 ife patterns in declaration order
//     [STRIPES, GRID, DOTS, PLAIN, STARS, FLOWERS, HEARTS, WAVES, CHECKERS],
//     swatches tinted with the tool color (jhe:201-209, lfe.a(i,color,ix4)),
//     current pattern marked (z = i == ife.I); each click wraps
//     ej9(29) → i31 case26 → nh9(patternOrdinal).
//   lfe.b — the tape tool's settings row previews the current pattern.
//   ife.I — pattern id = enum ordinal (TapePattern 0..8 parity).
//   nh9 → yh9(i3=1) — g5f.h(state,null,ordinal,15) copies the tool state with
//     the new tapePattern; ti9.q applies + persists (tool_state.tape_pattern).
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const PICKER = 'note/src/main/ets/ui/editor/TapePatternPicker.ets';
const DIALOG = 'note/src/main/ets/ui/editor/ToolboxSettingsDialog.ets';
const VM = 'note/src/main/ets/ui/editor/EditorViewModel.ets';
const STRINGS = 'note/src/main/resources/base/element/string.json';
const STRINGS_ZH = 'note/src/main/resources/zh_CN/element/string.json';

const picker = readFileSync(PICKER, 'utf8');
const dialog = readFileSync(DIALOG, 'utf8');
const vm = readFileSync(VM, 'utf8');
const strings = readFileSync(STRINGS, 'utf8');
const stringsZh = readFileSync(STRINGS_ZH, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- Picker content (lfe.a: 9 patterns in ife order, tool-color swatches) ---
check(picker.includes('TAPE_PATTERN_ORDER'),
  'picker iterates the original pattern order');
const order = picker.slice(picker.indexOf('TAPE_PATTERN_ORDER'),
  picker.indexOf('TAPE_PATTERN_ORDER') + 400);
for (const p of ['STRIPES', 'GRID', 'DOTS', 'PLAIN', 'STARS', 'FLOWERS',
  'HEARTS', 'WAVES', 'CHECKERS']) {
  check(order.includes(`TapePattern.${p}`), `pattern ${p} present`);
}
check(order.indexOf('STRIPES') < order.indexOf('GRID') &&
  order.indexOf('GRID') < order.indexOf('DOTS') &&
  order.indexOf('DOTS') < order.indexOf('PLAIN') &&
  order.indexOf('PLAIN') < order.indexOf('STARS') &&
  order.indexOf('STARS') < order.indexOf('FLOWERS') &&
  order.indexOf('FLOWERS') < order.indexOf('HEARTS') &&
  order.indexOf('HEARTS') < order.indexOf('WAVES') &&
  order.indexOf('WAVES') < order.indexOf('CHECKERS'),
  'ife declaration order preserved');
check(picker.includes('renderTapePattern'), 'swatches reuse the tape tile renderer');
check(picker.includes('this.tool.brush.color'), 'swatches tinted with tool color');
check(picker.includes('this.tool.tapePattern === pattern'),
  'current pattern marked selected');
check(picker.includes('TapePattern.PLAIN'),
  'PLAIN renders as a solid band (no pattern layer)');

// --- Selection write (nh9 → g5f.h copy → ti9.q persist) ---
check(picker.includes('setToolTapePattern'), 'pick dispatches the tool-state write');
const setter = vm.slice(vm.indexOf('setToolTapePattern'));
check(setter.includes('state.tapePattern = pattern'),
  'tapePattern written onto the tool state (g5f.h parity)');
check(setter.includes('target.toolType !== ToolType.REVIEW'),
  'setter restricted to REVIEW rows (dm2 parity)');
check(vm.includes('updateState(toolId'), 'updateState persists via saveToolState');

// --- Surface (toolbox settings row → picker sheet) ---
check(dialog.includes('TapePatternPicker'), 'dialog hosts the picker');
check(dialog.includes("tool.toolType === ToolType.REVIEW") &&
  dialog.includes("$r('app.string.tape_patterns')"),
  'REVIEW rows expose the pattern menu item');
check(dialog.includes('tapePatternToolId = tool.toolId'),
  'menu item opens the picker for the row');
check(dialog.includes('findToolById'), 'picker receives the tool row');

// --- Strings ---
check(strings.includes('"name": "tape_patterns"') &&
  strings.includes('"value": "Tape Pattern"'), 'EN tape_patterns string');
check(stringsZh.includes('"name": "tape_patterns"'), 'zh_CN tape_patterns string');

console.log(`D02_ORIGINAL_TAPE_PATTERN_PICKER_OK TOTAL=${n} FAILED=0`);
