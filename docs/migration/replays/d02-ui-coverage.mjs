// Phase 1314 — Harmony ui/ layer coverage
import { existsSync, readdirSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/ui/';
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('editor components', X('editor/NoteCanvasView.ets') && X('editor/EditorToolbar.ets') && X('editor/NotePage.ets'));
t('stylus adapter', X('editor/ArkUIStylusAdapter.ets'));
t('page manager+overview', X('editor/PageManagerBar.ets') && X('editor/PageOverviewPanel.ets'));
t('recording panel', X('editor/RecordingPanel.ets'));
t('toolbox settings', X('editor/ToolboxSettingsDialog.ets'));
t('library', X('library/LibraryPage.ets'));
t('settings', X('settings/SettingsPage.ets') && X('settings/BackupPage.ets'));
t('WebDAV settings', X('settings/WebDAVSettingsPage.ets'));
t('theme', X('theme/EditorTheme.ets') && X('theme/ThemeStore.ets'));
t('components 10+', readdirSync(S + 'components').filter(f => f.endsWith('.ets')).length >= 10);
console.log('ui-coverage replay: ' + n + '/10 checks green');
