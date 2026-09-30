// Phase 1339 — library + settings UI
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const L = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/ui/library/';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/ui/settings/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const lp = readFileSync(L + 'LibraryPage.ets', 'utf8');
t('folder meta ref (e47)', lp.includes('e47') || lp.includes('SyncedFolderMetadata'));
t('view mode ref (ie7)', lp.includes('ie7'));
t('grid default', lp.includes('GRID') || lp.includes('grid'));
t('emoji picker ref (du3)', lp.includes('du3') || lp.includes('emoji'));
t('listView state', lp.includes('listView'));
t('LibraryViewModel', existsSync(L + 'LibraryViewModel.ets'));
t('SettingsPage', existsSync(S + 'SettingsPage.ets'));
t('WebDAVSettingsPage', existsSync(S + 'WebDAVSettingsPage.ets'));
t('BackupPage', existsSync(S + 'BackupPage.ets'));
t('RecentlyDeletedPage', existsSync(S + 'RecentlyDeletedPage.ets'));
console.log('library-ui replay: ' + n + '/10 checks green');
