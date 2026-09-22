// Phase 560 — original "Keep device awake" note-editor setting.
// Original evidence: r22 case 2 renders the feature_settings__keep_device_awake
// toggle in the note-editor settings section; the flag keeps the screen on
// while the note view is foregrounded (Android FLAG_KEEP_SCREEN_ON semantics;
// the native consumer is not in the decompiled surface — registered).
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const store = readFileSync('note/src/main/ets/data/EditorSettingsStore.ets', 'utf8');
const settings = readFileSync('note/src/main/ets/ui/settings/SettingsPage.ets', 'utf8');
const page = readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8');
const fake = readFileSync('note/src/test/EditorViewModel.test.ets', 'utf8');
const baseJson = JSON.parse(readFileSync('note/src/main/resources/base/element/string.json', 'utf8'));
const zhJson = JSON.parse(readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8'));
const baseVal = n => baseJson.string.find(e => e.name === n)?.value;
const zhVal = n => zhJson.string.find(e => e.name === n)?.value;

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- Strings ---
check(baseVal('keep_device_awake') === 'Keep device awake', 'EN verbatim');
check(zhVal('keep_device_awake')?.length > 0, 'zh present');

// --- Store: pref key + interface + rollback save ---
check(store.includes("KEEP_DEVICE_AWAKE_KEY"), 'pref key defined');
check(store.includes('getKeepDeviceAwake()'), 'getKeepDeviceAwake in interface');
check(store.includes('saveKeepDeviceAwake(enabled'), 'saveKeepDeviceAwake in interface');
check(store.includes('DEFAULT_KEEP_DEVICE_AWAKE'), 'default constant');
check(/saveKeepDeviceAwake[\s\S]*?deleteSync\(KEEP_DEVICE_AWAKE_KEY\)/.test(store),
  'save rollback restores previous on flush failure');

// --- SettingsPage: state, load, toggle row, rollback setter ---
check(settings.includes('@State keepDeviceAwakeEnabled'), 'page state');
check(settings.includes('await store.getKeepDeviceAwake()'), 'load path');
check(settings.includes("$r('app.string.keep_device_awake')"), 'toggle row label');
check(settings.includes('setKeepDeviceAwakeEnabled(enabled)'), 'toggle wiring');
check(/setKeepDeviceAwakeEnabled[\s\S]*?lifecycleGeneration/.test(settings), 'lifecycle guard');
check(/setKeepDeviceAwakeEnabled[\s\S]*?keepDeviceAwakeEnabled = previous/.test(settings),
  'save failure rolls back');

// --- NotePage: applied via setWindowKeepScreenOn, cleared on exit ---
check(page.includes('setWindowKeepScreenOn'), 'keep-screen-on applied');
check(page.includes('applyKeepDeviceAwakeSetting'), 'load method');
check(page.includes('keepAwakeGeneration'), 'generation guard');
check(page.includes('keepScreenOnApplied'), 'applied flag');
check(/aboutToDisappear[\s\S]{0,800}setKeepScreenOn\(false\)/.test(page), 'cleared on disappear');
check(/aboutToAppear[\s\S]{0,4000}applyKeepDeviceAwakeSetting/.test(page), 'applied on appear');

// --- Test fake implements the widened interface ---
check(fake.includes('getKeepDeviceAwake'), 'fake getKeepDeviceAwake');
check(fake.includes('saveKeepDeviceAwake'), 'fake saveKeepDeviceAwake');

console.log(`TOTAL=${n}`);
