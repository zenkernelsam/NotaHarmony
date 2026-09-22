// Phase 564 — original palm detection setting.
// Original evidence: x22 case 2 renders feature_settings__palm_detection +
// _description ("Palm Detection lets you rest your palm anywhere while
// writing"); o59.c truth table: palmDetectionEnabled defaults TRUE.
// Harmony landing: while a stylus (SourceTool.Pen) stroke session is active,
// extra non-pen touches are ignored instead of cancelling the stroke —
// matching "rest your palm anywhere while writing".
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
check(baseVal('palm_detection') === 'Palm detection', 'title EN');
check(baseVal('palm_detection_description') ===
  'Palm Detection lets you rest your palm anywhere while writing.', 'desc EN');
check(zhVal('palm_detection')?.length > 0, 'title zh');
check(zhVal('palm_detection_description')?.length > 0, 'desc zh');

// --- Store ---
check(store.includes('PALM_DETECTION_KEY'), 'pref key');
check(store.includes("'palmDetectionEnabled'"), 'original datastore key name');
check(store.includes('getPalmDetectionEnabled()') && store.includes('savePalmDetectionEnabled('),
  'iface');
check(/DEFAULT_PALM_DETECTION: boolean = true/.test(store),
  'default true (o59.c truth table)');

// --- SettingsPage ---
check(settings.includes('@State palmDetectionEnabled'), 'state');
check(settings.includes('await store.getPalmDetectionEnabled()'), 'load');
check(settings.includes("$r('app.string.palm_detection')"), 'title label');
check(settings.includes("$r('app.string.palm_detection_description')"), 'description rendered');
check(settings.includes('setPalmDetectionEnabled(enabled)'), 'wiring');
check(/setPalmDetectionEnabled[\s\S]*?lifecycleGeneration/.test(settings), 'guard');
check(/setPalmDetectionEnabled[\s\S]*?palmDetectionEnabled = previous/.test(settings), 'rollback');

// --- ViewModel ---
check(vm.includes('palmDetectionEnabled: boolean'), 'vm field');
check(vm.includes('await settingsRepository.getPalmDetectionEnabled()'), 'vm load');

// --- Canvas: palm rejection guards ---
check(canvas.includes('palmRejectionActive'), 'rejection helper');
check(/palmRejectionActive[\s\S]{0,300}strokeSession\.isActive\(\)/.test(canvas),
  'requires active stroke session');
check(/palmRejectionActive[\s\S]{0,300}activeStrokeStylus/.test(canvas),
  'requires stylus-driven stroke');
check(canvas.includes('event.sourceTool === SourceTool.Pen'), 'stylus flag source');
// down: extra non-pen touch ignored instead of cancelling
check(/touches\.length > 1[\s\S]{0,200}palmRejectionActive\(\) && event\.sourceTool !== SourceTool\.Pen/
  .test(canvas), 'down guard ignores palm');
// move: >1 touches tolerated under rejection
check(/event\.touches\.length > 1 && !this\.palmRejectionActive\(\)/.test(canvas),
  'move guard');
// up: palm-lift while pen down ignored; remaining palm touches tolerated
check(/palmRejectionActive\(\)[\s\S]{0,120}findTouchById\(event\.changedTouches/.test(canvas),
  'up guard ignores palm lift');
check(/event\.touches\.length > 0 && !this\.palmRejectionActive\(\)/.test(canvas),
  'up tolerate remaining palms');
// flag reset with pointer tracking
check(/resetPointerTracking[\s\S]{0,150}activeStrokeStylus = false/.test(canvas), 'flag reset');

// --- Test fake ---
check(fake.includes('getPalmDetectionEnabled') && fake.includes('savePalmDetectionEnabled'),
  'fake methods');

console.log(`TOTAL=${n}`);
