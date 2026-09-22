// Phase 562 — original note-view night mode setting.
// Original evidence: r22 case 1 renders feature_settings__note_view_night_mode
// ("Note view night mode") + _caption ("View your notes (paper and ink) with
// a dark appearance") in the note-editor settings section. Harmony landing:
// the editor resolves DarkTheme tokens for both chrome AND the paper/ink
// render path (PaperRenderer already darkens paper via theme.paperBackground).
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const store = readFileSync('note/src/main/ets/data/EditorSettingsStore.ets', 'utf8');
const settings = readFileSync('note/src/main/ets/ui/settings/SettingsPage.ets', 'utf8');
const page = readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8');
const canvas = readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');
const fake = readFileSync('note/src/test/EditorViewModel.test.ets', 'utf8');
const baseJson = JSON.parse(readFileSync('note/src/main/resources/base/element/string.json', 'utf8'));
const zhJson = JSON.parse(readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8'));
const baseVal = n => baseJson.string.find(e => e.name === n)?.value;
const zhVal = n => zhJson.string.find(e => e.name === n)?.value;

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- Strings (EN verbatim) ---
check(baseVal('note_view_night_mode') === 'Note view night mode', 'title EN');
check(baseVal('note_view_night_mode_caption') ===
  'View your notes (paper and ink) with a dark appearance', 'caption EN');
check(zhVal('note_view_night_mode')?.length > 0, 'title zh');
check(zhVal('note_view_night_mode_caption')?.length > 0, 'caption zh');

// --- Store ---
check(store.includes('NOTE_VIEW_NIGHT_MODE_KEY'), 'pref key');
check(store.includes('getNoteViewNightMode()') && store.includes('saveNoteViewNightMode('), 'iface');
check(store.includes('DEFAULT_NOTE_VIEW_NIGHT_MODE'), 'default const');

// --- SettingsPage ---
check(settings.includes('@State noteViewNightModeEnabled'), 'state');
check(settings.includes('await store.getNoteViewNightMode()'), 'load');
check(settings.includes("$r('app.string.note_view_night_mode')"), 'title label');
check(settings.includes("$r('app.string.note_view_night_mode_caption')"), 'caption rendered');
check(settings.includes('setNoteViewNightModeEnabled(enabled)'), 'wiring');
check(/setNoteViewNightModeEnabled[\s\S]*?lifecycleGeneration/.test(settings), 'guard');
check(/setNoteViewNightModeEnabled[\s\S]*?noteViewNightModeEnabled = previous/.test(settings),
  'rollback');

// --- NotePage: state + dark token resolution + canvas prop ---
check(page.includes('@State noteViewNightMode'), 'page state');
check(page.includes('applyNoteViewNightModeSetting'), 'load method');
check(page.includes('nightModeGeneration'), 'generation guard');
check(page.includes("this.noteViewNightMode ? 'dark'"), 'dark token override');
check(page.includes('nightMode: this.noteViewNightMode'), 'prop passed to canvas');
check(/aboutToAppear[\s\S]{0,4500}applyNoteViewNightModeSetting/.test(page), 'applied on appear');
check(/aboutToDisappear[\s\S]{0,900}nightModeGeneration\+\+/.test(page), 'invalidated on disappear');

// --- Canvas: prop + dark resolution + redraw on change ---
check(canvas.includes("@Prop @Watch('onNightModeChange') nightMode"), 'canvas prop');
check(canvas.includes("this.nightMode ? 'dark'"), 'canvas dark override');
check(canvas.includes('const theme: ThemeTokens = this.resolveTokens()'),
  'paper render uses overridden tokens');
check(/onNightModeChange[\s\S]{0,200}renderFrame\(true\)/.test(canvas), 'redraw on change');

// --- Test fake ---
check(fake.includes('getNoteViewNightMode') && fake.includes('saveNoteViewNightMode'), 'fake methods');

console.log(`TOTAL=${n}`);
