// Phase 1167 — app entry + widgets + native-fallback
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const B = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/app/';
const R = f => readFileSync(B + f, 'utf8');
const has = f => existsSync(B + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('NbApplication exists', has('NbApplication.java'));
t('MainActivity exists', has('MainActivity.java'));
t('MissingNativeLibraryActivity exists', has('MissingNativeLibraryActivity.java'));
t('MissingNativeLibraryActivity extends Activity', R('MissingNativeLibraryActivity.java').includes('extends Activity'));
t('MissingNativeLibrary onCreate', R('MissingNativeLibraryActivity.java').includes('onCreate(Bundle'));
t('AppUpgradeReceiver BroadcastReceiver', R('AppUpgradeReceiver.java').includes('extends BroadcastReceiver'));
t('initializers present', has('initializers/AppStartupInitializer.java') && has('initializers/LoggingInitializer.java'));
t('widgets: CreateNote+Recording', has('widgets/CreateNoteWidgetProvider.java') && has('widgets/CreateRecordingWidgetProvider.java'));
t('widgets: FolderNotes+Thumbnail+Recent', has('widgets/FolderNotesWidgetProvider.java') && has('widgets/NoteThumbnailWidgetProvider.java') && has('widgets/RecentNotesWidgetProvider.java'));
t('widget providers extend do2 (AppWidgetProvider)', R('widgets/CreateNoteWidgetProvider.java').includes('extends do2') && R('widgets/CreateRecordingWidgetProvider.java').includes('extends do2'));
console.log('app replay: ' + n + '/10 checks green');
