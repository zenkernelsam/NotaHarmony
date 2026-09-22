// Phase 563 — original auto-deselect-eraser setting.
// Original evidence: x22 case 3 renders feature_settings__auto_deselect_eraser
// + _description ("After erasing, the toolbox auto-switches back to your last
// used tool."); i8f.d reads l59.f (autoDeselectEraser) and, when set, selects
// epi.c(toolbox) — the previously selected tool. o59.c truth table: pref key
// "autoDeselectEraser" defaults false; hideStatusBar/hideNavigationBar default
// true (evidence correction of the Phase 561 assumption).
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
check(baseVal('auto_deselect_eraser') === 'Auto-deselect eraser', 'title EN');
check(baseVal('auto_deselect_eraser_description') ===
  'After erasing, the toolbox auto-switches back to your last used tool.', 'desc EN');
check(zhVal('auto_deselect_eraser')?.length > 0, 'title zh');
check(zhVal('auto_deselect_eraser_description')?.length > 0, 'desc zh');

// --- Store ---
check(store.includes('AUTO_DESELECT_ERASER_KEY'), 'pref key');
check(store.includes("'autoDeselectEraser'"), 'original datastore key name');
check(store.includes('getAutoDeselectEraser()') && store.includes('saveAutoDeselectEraser('),
  'iface');
check(/DEFAULT_AUTO_DESELECT_ERASER: boolean = false/.test(store),
  'default false (o59.c truth table)');
// o59.c evidence fix: hide bars default true (opt-out), not the Phase 561 guess.
check(/DEFAULT_HIDE_STATUS_BAR: boolean = true/.test(store), 'hideStatusBar default true');
check(/DEFAULT_HIDE_NAVIGATION_BAR: boolean = true/.test(store), 'hideNavigationBar default true');
check(/DEFAULT_KEEP_DEVICE_AWAKE: boolean = false/.test(store), 'keepAwake default false');
check(/DEFAULT_NOTE_VIEW_NIGHT_MODE: boolean = false/.test(store), 'nightView default false');

// --- SettingsPage ---
check(settings.includes('@State autoDeselectEraserEnabled'), 'state');
check(settings.includes('await store.getAutoDeselectEraser()'), 'load');
check(settings.includes("$r('app.string.auto_deselect_eraser')"), 'title label');
check(settings.includes("$r('app.string.auto_deselect_eraser_description')"), 'description rendered');
check(settings.includes('setAutoDeselectEraserEnabled(enabled)'), 'wiring');
check(/setAutoDeselectEraserEnabled[\s\S]*?lifecycleGeneration/.test(settings), 'guard');
check(/setAutoDeselectEraserEnabled[\s\S]*?autoDeselectEraserEnabled = previous/.test(settings),
  'rollback');

// --- ViewModel ---
check(vm.includes('autoDeselectEraser: boolean'), 'vm field');
check(vm.includes('await settingsRepository.getAutoDeselectEraser()'), 'vm load');
check(vm.includes('autoDeselectEraserAfterUse'), 'vm method');
check(/autoDeselectEraserAfterUse[\s\S]{0,400}previousToolId/.test(vm), 'restores previous tool');
check(/autoDeselectEraserAfterUse[\s\S]{0,400}selectToolById/.test(vm), 'selects via toolbox');

// --- Canvas hook: after applyEraser() on touch-up ---
check(/applyEraser\(\);[\s\S]{0,200}autoDeselectEraserAfterUse/.test(canvas),
  'deselect after eraser gesture');
check(/autoDeselectEraserAfterUse\(\)\.catch/.test(canvas), 'error path guarded');

// --- Test fake ---
check(fake.includes('getAutoDeselectEraser') && fake.includes('saveAutoDeselectEraser'),
  'fake methods');

console.log(`TOTAL=${n}`);
