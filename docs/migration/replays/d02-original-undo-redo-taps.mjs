// Phase 1399 — original two/three-finger tap undo/redo.
// Original evidence:
//   data_onboarding__first_undo_redo_tooltip_text = "Two finger tap to quickly
//     Undo, three finger tap to Redo";
//   feature_settings__two_finger_tap = "2 finger tap",
//   feature_settings__two_finger_tap_description =
//     "2 finger tap to undo, 3 finger tap to redo.";
//   o8b.P = dcd("undoRedoTapsEnabled") — o8b.f decodes proto field P with
//     `null → true` (bool6 != null ? bool6 : true), i.e. default ON;
//   kd4 case 15 renders the settings row via nf6(j8b.C) UiState;
//   q8j = {Undecided, Scroll, Pinch} two-finger gesture disambiguation — a tap
//     only fires undo when the touch sequence did not become a scroll/pinch
//     (ArkUI TapGesture encodes the same contract: movement past the touch
//     slop or a long hold fails the recognizer);
//   i0i: undo on an empty stack is an error path — Harmony guards with
//     undoRedo.canUndo()/canRedo() before entering performHistory.
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

// --- Strings (EN verbatim from resources/res/values/strings.xml) ---
check(baseVal('two_finger_tap') === '2 finger tap', 'title EN');
check(baseVal('two_finger_tap_description') ===
  '2 finger tap to undo, 3 finger tap to redo.', 'desc EN');
check(zhVal('two_finger_tap')?.length > 0, 'title zh');
check(zhVal('two_finger_tap_description')?.length > 0, 'desc zh');

// --- Store (o8b.P, original datastore key name "undoRedoTapsEnabled") ---
check(store.includes('UNDO_REDO_TAPS_KEY'), 'pref key const');
check(store.includes("'undoRedoTapsEnabled'"), 'original datastore key name');
check(store.includes('getUndoRedoTapsEnabled()') && store.includes('saveUndoRedoTapsEnabled('),
  'iface pair');
check(/DEFAULT_UNDO_REDO_TAPS: boolean = true/.test(store),
  'default true (o8b.f: proto field P null → true)');
check(/getBooleanPref\(UNDO_REDO_TAPS_KEY, DEFAULT_UNDO_REDO_TAPS\)/.test(store), 'getter');
check(/saveBooleanPref\(UNDO_REDO_TAPS_KEY, enabled/.test(store), 'setter');

// --- SettingsPage (kd4 case 15 row) ---
check(settings.includes('@State undoRedoTapsEnabled'), 'state');
check(settings.includes('await store.getUndoRedoTapsEnabled()'), 'load');
check(settings.includes('this.undoRedoTapsEnabled = undoRedoTaps'), 'load assign');
check(settings.includes("$r('app.string.two_finger_tap')"), 'title label');
check(settings.includes("$r('app.string.two_finger_tap_description')"), 'description rendered');
check(/Toggle\(\{ type: ToggleType\.Switch, isOn: this\.undoRedoTapsEnabled \}\)/.test(settings),
  'toggle bound');
check(settings.includes('setUndoRedoTapsEnabled(enabled)'), 'wiring');
check(/setUndoRedoTapsEnabled[\s\S]*?lifecycleGeneration/.test(settings), 'guard');
check(/setUndoRedoTapsEnabled[\s\S]*?undoRedoTapsEnabled = previous/.test(settings), 'rollback');

// --- ViewModel (j8b.C → UiState) ---
check(/undoRedoTapsEnabled: boolean = true/.test(vm), 'vm field default true');
check(vm.includes('await settingsRepository.getUndoRedoTapsEnabled()'), 'vm load');

// --- Canvas gestures (2-finger tap → undo, 3-finger tap → redo) ---
check(/TapGesture\(\{ count: 1, fingers: 2 \}\)[\s\S]{0,400}undoStroke\(\)/.test(canvas),
  '2-finger tap → undo');
check(/TapGesture\(\{ count: 1, fingers: 3 \}\)[\s\S]{0,400}redoStroke\(\)/.test(canvas),
  '3-finger tap → redo');
check(/fingers: 2[\s\S]{0,200}undoRedoTapsEnabled/.test(canvas), 'undo gated on setting');
check(/fingers: 3[\s\S]{0,200}undoRedoTapsEnabled/.test(canvas), 'redo gated on setting');
check(/undoRedoTapsEnabled[\s\S]{0,120}canUndo\(\)/.test(canvas),
  'undo gated on canUndo (i0i empty-stack error path)');
check(/undoRedoTapsEnabled[\s\S]{0,120}canRedo\(\)/.test(canvas),
  'redo gated on canRedo');
check(/fingers: 2[\s\S]{0,300}photoImportBusy/.test(canvas), 'undo tap gated on import lease');
check(/fingers: 3[\s\S]{0,300}photoImportBusy/.test(canvas), 'redo tap gated on import lease');

// --- Gesture-group placement: taps share the Parallel group with pinch/pan ---
const gestureStart = canvas.indexOf('GestureGroup(GestureMode.Parallel');
const gestureEnd = canvas.indexOf('GestureMode.Exclusive', gestureStart);
check(gestureStart > 0, 'parallel gesture group exists');
const parallel = canvas.slice(gestureStart, gestureEnd > gestureStart ? gestureEnd : gestureStart + 4000);
check(parallel.includes('PinchGesture({ fingers: 2 })'), 'pinch in group');
check(parallel.includes('PanGesture({ fingers: 2 })'), 'pan in group');
check(parallel.includes('TapGesture({ count: 1, fingers: 2 })'), 'undo tap in group');
check(parallel.includes('TapGesture({ count: 1, fingers: 3 })'), 'redo tap in group');

// --- Test fake implements the new repository surface ---
check(fake.includes('getUndoRedoTapsEnabled') && fake.includes('saveUndoRedoTapsEnabled'),
  'fake methods');

console.log(`TOTAL=${n}`);
