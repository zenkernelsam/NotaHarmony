// Phase 561 — original note-view immersive toggles.
// Original evidence: r22 case 3/4 render feature_settings__hide_status_bar
// ("Hide status bar in note view") and hide_navigation_bar ("Hide navigation
// bar in note view") in the note-editor settings section; the immersive
// application is native (WindowInsets/systemUiVisibility) — not in the
// decompiled surface. Portable contract: persisted toggles + note-view
// application via setSpecificSystemBarEnabled.
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

// --- Strings (EN verbatim from original) ---
check(baseVal('hide_status_bar') === 'Hide status bar in note view', 'hide_status_bar EN');
check(baseVal('hide_navigation_bar') === 'Hide navigation bar in note view', 'hide_navigation_bar EN');
check(zhVal('hide_status_bar')?.length > 0, 'hide_status_bar zh');
check(zhVal('hide_navigation_bar')?.length > 0, 'hide_navigation_bar zh');

// --- Store: keys + interface + rollback path ---
check(store.includes('HIDE_STATUS_BAR_KEY') && store.includes('HIDE_NAVIGATION_BAR_KEY'), 'pref keys');
check(store.includes('getHideStatusBar()') && store.includes('saveHideStatusBar('), 'status-bar iface');
check(store.includes('getHideNavigationBar()') && store.includes('saveHideNavigationBar('), 'nav-bar iface');
check(/saveBooleanPref[\s\S]*?deleteSync\(key\)/.test(store), 'shared rollback path');

// --- SettingsPage: state, load, two toggle rows, guarded setters ---
check(settings.includes('@State hideStatusBarEnabled'), 'status state');
check(settings.includes('@State hideNavigationBarEnabled'), 'nav state');
check(settings.includes('await store.getHideStatusBar()') &&
  settings.includes('await store.getHideNavigationBar()'), 'load path');
check(settings.includes("$r('app.string.hide_status_bar')"), 'status toggle label');
check(settings.includes("$r('app.string.hide_navigation_bar')"), 'nav toggle label');
check(settings.includes('setHideStatusBarEnabled(enabled)') &&
  settings.includes('setHideNavigationBarEnabled(enabled)'), 'toggle wiring');
check(/setHideStatusBarEnabled[\s\S]*?lifecycleGeneration/.test(settings), 'status guard');
check(/setHideNavigationBarEnabled[\s\S]*?lifecycleGeneration/.test(settings), 'nav guard');
check(/setHideStatusBarEnabled[\s\S]*?hideStatusBarEnabled = previous/.test(settings), 'status rollback');
check(/setHideNavigationBarEnabled[\s\S]*?hideNavigationBarEnabled = previous/.test(settings), 'nav rollback');

// --- NotePage: immersive application + restore on exit ---
check(page.includes('applyHideSystemBarsSetting'), 'load method');
check(page.includes('systemBarsGeneration'), 'generation guard');
check(page.includes("setSpecificSystemBarEnabled"), 'system bar API');
check(page.includes("'status'") && page.includes("'navigation'") &&
  page.includes("'navigationIndicator'"), 'all bar kinds covered');
check(/aboutToDisappear[\s\S]{0,1200}setSystemBarHidden\('status', false\)/.test(page),
  'status bar restored on disappear');
check(/aboutToDisappear[\s\S]{0,1200}setSystemBarHidden\('navigation', false\)/.test(page),
  'nav bar restored on disappear');
check(/aboutToAppear[\s\S]{0,4000}applyHideSystemBarsSetting/.test(page), 'applied on appear');

// --- Test fake implements widened interface ---
check(fake.includes('getHideStatusBar') && fake.includes('getHideNavigationBar'), 'fake getters');
check(fake.includes('saveHideStatusBar') && fake.includes('saveHideNavigationBar'), 'fake setters');

console.log(`TOTAL=${n}`);
