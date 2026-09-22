// Phase 566 — original Appearance settings (match-system + dark theme).
// Original evidence: r22 case 0 renders feature_settings__match_system_appearance;
// g8 renders feature_settings__dark_theme. The pair collapses to the nve enum
// {MATCH_SYSTEM, LIGHT, DARK}. s3d's settings directory order places
// appearance before note_editor. Harmony landing: two toggle rows in a new
// Appearance section, persisted via the existing library_prefs/theme_mode +
// ThemeStore path (same as LibraryPage's theme menu).
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const settings = readFileSync('note/src/main/ets/ui/settings/SettingsPage.ets', 'utf8');
const baseJson = JSON.parse(readFileSync('note/src/main/resources/base/element/string.json', 'utf8'));
const zhJson = JSON.parse(readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8'));
const baseVal = n => baseJson.string.find(e => e.name === n)?.value;
const zhVal = n => zhJson.string.find(e => e.name === n)?.value;

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- Strings (EN verbatim) ---
check(baseVal('appearance') === 'Appearance', 'section title EN');
check(baseVal('match_system_appearance') === 'Match system appearance', 'match EN');
check(baseVal('dark_theme') === 'Dark theme', 'dark EN (pre-existing)');
check(zhVal('appearance')?.length > 0, 'appearance zh');
check(zhVal('match_system_appearance')?.length > 0, 'match zh');

// --- SettingsPage ---
check(settings.includes("$r('app.string.appearance')"), 'section header');
check(settings.includes("$r('app.string.match_system_appearance')"), 'match label');
check(settings.includes("$r('app.string.dark_theme')"), 'dark label');
// match toggle reads/writes themeMode === 'system'
check(settings.includes("this.themeMode === 'system'"), 'match reads mode');
check(settings.includes('setMatchSystemAppearance(enabled)'), 'match wiring');
check(/setMatchSystemAppearance[\s\S]{0,300}applyThemeMode\('system'\)/.test(settings),
  'match on → system');
check(/setMatchSystemAppearance[\s\S]{0,400}systemDark \? 'dark' : 'light'/.test(settings),
  'match off → preserves current visual');
// dark toggle maps to 'dark'/'light'
check(settings.includes('setDarkThemeEnabled(enabled)'), 'dark wiring');
check(/setDarkThemeEnabled[\s\S]{0,200}applyThemeMode\(enabled \? 'dark' : 'light'\)/.test(settings),
  'dark toggle → dark/light');
// dark row disabled under match-system (match overrides explicit choice)
check(/enabled\(!this\.saveBusy && this\.themeMode !== 'system'\)/.test(settings),
  'dark row disabled when matching system');
// persistence rides the existing library_prefs/theme_mode path
check(settings.includes('THEME_PREFERENCE_KEY'), 'persisted pref key');
check(settings.includes('ThemeStore.setMode(mode)'), 'ThemeStore write');
check(settings.includes('pref.flush()'), 'pref flush');
check(settings.includes('THEME_PREFERENCES_NAME'), 'prefs name');
// section order: appearance before note_editor (s3d directory order)
check(settings.indexOf("$r('app.string.appearance')") <
  settings.indexOf("$r('app.string.note_editor')"), 'section order');
// lifecycle guards on the async persist
check(/applyThemeMode[\s\S]{0,400}lifecycleGeneration/.test(settings), 'generation guard');
check(/applyThemeMode[\s\S]{0,200}pageDisposed/.test(settings), 'disposal guard');

console.log(`TOTAL=${n}`);
