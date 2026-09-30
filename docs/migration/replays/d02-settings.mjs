// Phase 1295 — settings/preferences layer (Room DBs + DataStore initializers)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/';
const R = f => readFileSync(S + f, 'utf8');
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('SettingsDatabase x5c Room', R('data/settings/database/SettingsDatabase.java').includes('extends x5c'));
t('ToolboxDatabase x5c Room', R('data/toolbar/database/ToolboxDatabase.java').includes('extends x5c'));
t('SettingsDatabase_Impl', X('data/settings/database/SettingsDatabase_Impl.java'));
t('ToolboxDatabase_Impl', X('data/toolbar/database/ToolboxDatabase_Impl.java'));
const td = R('data/theme/ThemeDataStoreInitializer.java');
t('ThemeDataStoreInitializer', td.length > 0);
const ne = R('data/settings/NoteEditorSettingsInitializer.java');
t('NoteEditorSettingsInitializer', ne.length > 0);
const hp = R('data/stylus/haptic/HapticPreferencesInitializer.java');
t('HapticPreferencesInitializer', hp.length > 0);
const ud = R('core/user/UserDataStoreInitializer.java');
t('UserDataStoreInitializer', ud.length > 0);
const se = R('data/subscription/storage/SerializationException.java');
t('subscription SerializationException', se.includes('Exception'));
t('initializer pattern', /Initializer/.test(td) && /Initializer/.test(ne) && /Initializer/.test(hp));
console.log('settings replay: ' + n + '/10 checks green');
