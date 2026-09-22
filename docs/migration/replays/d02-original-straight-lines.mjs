// Phase 565 — original straight-lines setting + detection gating split.
// Original evidence: x22 case 0 renders feature_settings__straight_lines
// ("Straight lines") + caption "Use the pen, pencil, or highlighter to draw
// a line, then continue to hold down to automatically straighten it." —
// separate from shapes_detection (case 1, same hold gesture, shapes).
// o59.c truth table: straightLinesEnabled defaults true. Harmony landing:
// either flag enables hold-detection; LINE results require
// straightLinesEnabled, non-LINE results require shapeDetectionEnabled.
// Also lands the missing shapes_detection caption (v22 case 21).
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const store = readFileSync('note/src/main/ets/data/EditorSettingsStore.ets', 'utf8');
const settings = readFileSync('note/src/main/ets/ui/settings/SettingsPage.ets', 'utf8');
const vm = readFileSync('note/src/main/ets/ui/editor/EditorViewModel.ets', 'utf8');
const canvas = readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');
const fake = readFileSync('note/src/test/EditorViewModel.test.ets', 'utf8');
const baseJson = JSON.parse(readFileSync('note/src/main/resources/base/element/string.json', 'utf8'));
const zhJson = JSON.parse(readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8'));
const baseVal = n => baseJson.string.find(e => e.name === n)?.value;
const zhVal = n => zhJson.string.find(e => e.name === n)?.value;

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- Strings (EN verbatim) ---
check(baseVal('straight_lines') === 'Straight lines', 'title EN');
check(baseVal('straight_lines_description') ===
  'Use the pen, pencil, or highlighter to draw a line, then continue to hold down to automatically straighten it.',
  'desc EN');
check(baseVal('shape_detection_description') ===
  'Use the pen, pencil, or highlighter to draw a shape, then continue to hold down to automatically detect it.',
  'shape desc EN');
check(zhVal('straight_lines')?.length > 0, 'title zh');
check(zhVal('straight_lines_description')?.length > 0, 'desc zh');
check(zhVal('shape_detection_description')?.length > 0, 'shape desc zh');

// --- Store ---
check(store.includes('STRAIGHT_LINES_KEY'), 'pref key');
check(store.includes("'straightLinesEnabled'"), 'original datastore key name');
check(store.includes('getStraightLinesEnabled()') && store.includes('saveStraightLinesEnabled('),
  'iface');
check(/DEFAULT_STRAIGHT_LINES: boolean = true/.test(store), 'default true (o59.c)');

// --- SettingsPage ---
check(settings.includes('@State straightLinesEnabled'), 'state');
check(settings.includes('await store.getStraightLinesEnabled()'), 'load');
check(settings.includes("$r('app.string.straight_lines')"), 'title label');
check(settings.includes("$r('app.string.straight_lines_description')"), 'description rendered');
check(settings.includes("$r('app.string.shape_detection_description')"),
  'shapes caption landed (v22 case 21)');
check(settings.includes('setStraightLinesEnabled(enabled)'), 'wiring');
check(/setStraightLinesEnabled[\s\S]*?lifecycleGeneration/.test(settings), 'guard');
check(/setStraightLinesEnabled[\s\S]*?straightLinesEnabled = previous/.test(settings), 'rollback');
// original x22 order: straight_lines before shapes_detection
check(settings.indexOf("$r('app.string.straight_lines')") <
  settings.indexOf("$r('app.string.shape_detection')"), 'x22 row order');

// --- ViewModel ---
check(vm.includes('straightLinesEnabled: boolean'), 'vm field');
check(vm.includes('await settingsRepository.getStraightLinesEnabled()'), 'vm load');

// --- Canvas gating split ---
check(/shapeDetectionEnabled \|\||\|\| this\.viewModel\.shapeDetectionEnabled/.test(canvas) ||
  /straightLinesEnabled \|\| this\.viewModel\.shapeDetectionEnabled/.test(canvas),
  'either flag enables hold detection');
check(/element\.type === ElementType\.LINE[\s\S]{0,120}straightLinesEnabled/.test(canvas),
  'LINE gated by straightLinesEnabled');
check(/ElementType\.LINE[\s\S]{0,200}shapeDetectionEnabled/.test(canvas),
  'non-LINE gated by shapeDetectionEnabled');

// --- Test fake ---
check(fake.includes('getStraightLinesEnabled') && fake.includes('saveStraightLinesEnabled'),
  'fake methods');

console.log(`TOTAL=${n}`);
