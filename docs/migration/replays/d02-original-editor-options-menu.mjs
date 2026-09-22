// Phase 573 — original editor options menu (⋮ → "App settings").
// Original semantics decoded from decompiled_1.0.3:
//   rh8.java:1504  hamburger icon with a11y feature_note__toolbar_more_menu
//                  ("More options") renders unconditionally at the editor
//                  toolbar trailing edge.
//   rh8.java:1530  Template settings item gated by lc4.a(ac4.P)
//                  (TEMPLATE_SELECTION, zb4.L=PRODUCTION remote
//                  "androidTemplateSelection") — no Harmony backing screen.
//   rh8.java:1545  Version history gated by lc4.a(ac4.d0) (VERSION_HISTORY,
//                  PRODUCTION remote "androidVersionHistory") — epic.
//   rh8.java:1563  "App settings" (feature_note__options_menu_app_settings)
//                  renders unconditionally via apb.f — no flag/param gate.
//   rh8.java:1567+ Inky item gated by sc9.j runtime state (AI mascot) and
//                  "Disconnect stylus" by t9f.e stylus-connection state —
//                  neither infrastructure exists on Harmony.
//   x90.java:10582 rh8.f(...) invoked unconditionally in the toolbar row.
// Harmony ports the single unconditional production item (App settings →
// ui/settings/SettingsPage) and fails closed on the gated items.
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const PAGE = 'note/src/main/ets/ui/editor/NotePage.ets';
const STR_EN = 'note/src/main/resources/base/element/string.json';
const STR_ZH = 'note/src/main/resources/zh_CN/element/string.json';

const page = readFileSync(PAGE, 'utf8');
const strEn = readFileSync(STR_EN, 'utf8');
const strZh = readFileSync(STR_ZH, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- ⋮ button in the editor top nav row ---
check(page.includes("Button('...')"), 'more-options button');
const navRow = page.slice(page.indexOf('app.string.recordings'));
check(navRow.indexOf("Button('...')") > 0, '⋮ button follows Recordings button');
const moreBtn = navRow.slice(navRow.indexOf("Button('...')"),
  navRow.indexOf('bindMenu(this.buildEditorOptionsMenu())') + 45);
check(moreBtn.includes('accessibilityText($r(\'app.string.toolbar_more_menu\'))'),
  '⋮ button a11y = original toolbar_more_menu');
check(moreBtn.includes('bindMenu(this.buildEditorOptionsMenu())'),
  '⋮ button binds the options menu');
check(moreBtn.includes('!this.photoImportLeaseActive'),
  '⋮ button shares the lease/enabled guard');
check(moreBtn.includes('!this.pageLoading && !this.pageLoadFailed'),
  '⋮ button disabled while page loading/failed');

// --- Menu builder ---
check(page.includes('private buildEditorOptionsMenu(): MenuElement[]'),
  'options menu builder');
const menu = page.slice(page.indexOf('private buildEditorOptionsMenu'),
  page.indexOf('private navigateToSettings'));
check(menu.includes("$r('app.string.options_menu_app_settings')"),
  'App settings item present');
check(menu.includes('this.navigateToSettings()'), 'item routes to settings');
// Original gates: template settings / version history / inky / disconnect
// stylus must NOT appear — none are portable (remote-flag or missing infra).
check(!menu.includes('template_settings'), 'no template-settings item');
check(!menu.includes('version_history'), 'no version-history item');
check(!menu.includes('inky'), 'no inky item');
check(!menu.includes('disconnect'), 'no disconnect-stylus item');
// Exactly one menu element (the unconditional item).
const menuItems = menu.match(/\{ value: \$r\('app\.string\./g) || [];
check(menuItems.length === 1, 'menu contains only the unconditional item');

// --- Settings navigation ---
check(page.includes('private navigateToSettings(): void'), 'navigateToSettings');
const nav = page.slice(page.indexOf('private navigateToSettings'),
  page.indexOf('private navigateToSettings') + 500);
check(nav.includes("router.pushUrl({ url: 'ui/settings/SettingsPage' })"),
  'pushes SettingsPage route (same as library navigateToSettings)');
check(nav.includes('this.editorDisposed'), 'nav guards disposed editor');
check(nav.includes('this.photoImportLeaseActive'), 'nav guards photo lease');
check(nav.includes('catch'), 'pushUrl failure caught');
check(nav.includes('console.error'), 'pushUrl failure logged');

// --- Strings (EN verbatim + zh) ---
check(strEn.includes('"name": "options_menu_app_settings"'),
  'en options_menu_app_settings key');
check(strEn.includes('"value": "App settings"'), 'en "App settings" verbatim');
check(strZh.includes('"name": "options_menu_app_settings"'),
  'zh options_menu_app_settings key');
check(strZh.includes('"value": "应用设置"'), 'zh "应用设置"');
check(strEn.includes('"name": "toolbar_more_menu"'),
  'en toolbar_more_menu key');
check(strEn.includes('"value": "More options"'),
  'en "More options" verbatim');
check(strZh.includes('"name": "toolbar_more_menu"'), 'zh toolbar_more_menu key');
check(strZh.includes('"value": "更多选项"'), 'zh "更多选项"');

console.log(`D02_ORIGINAL_EDITOR_OPTIONS_MENU_REPLAY_OK TOTAL=${n} FAILED=0`);
