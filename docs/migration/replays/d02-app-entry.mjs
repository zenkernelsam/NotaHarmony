// Phase 1317 — Harmony app entry (NoteAbility + want ingress)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/';
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const na = readFileSync(S + 'noteability/NoteAbility.ets', 'utf8');
t('NoteAbility UIAbility', na.includes('extends UIAbility'));
t('onCreate', na.includes('onCreate'));
t('want ingress queues', na.includes('enqueueSharedWantUris') && na.includes('enqueueDeepLinkWant') && na.includes('enqueueLaunchAction'));
t('openTarget want', na.includes('enqueueOpenTargetWant'));
t('ThemeStore.init', na.includes('ThemeStore.init'));
t('onNewWant warm start', na.includes('onNewWant'));
t('onWindowStageCreate loadContent Index', na.includes('onWindowStageCreate') && na.includes("loadContent('pages/Index'"));
t('theme fallback', na.includes('restoreThemeAndLoadContent') && na.includes('loadMainContent'));
t('4 abilities', X('noteability/NoteAbility.ets') && X('notebackupability/NoteBackupAbility.ets') && X('noteformability/NoteFormAbility.ets'));
t('form edit abilities', X('noteformeditability/FolderFormEditAbility.ets') && X('noteformeditability/NoteThumbnailFormEditAbility.ets'));
console.log('app-entry replay: ' + n + '/10 checks green');
