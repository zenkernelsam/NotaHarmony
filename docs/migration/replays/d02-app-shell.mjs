// Phase 1296 — app shell (Hilt DI + Startup + native fallback)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/app/';
const R = f => readFileSync(S + f, 'utf8');
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const nb = R('NbApplication.java');
t('NbApplication extends Application fed', nb.includes('extends Application implements fed'));
t('NbApplication x30 component mgr', nb.includes('x30 I'));
const ma = R('MainActivity.java');
t('MainActivity extends r12', ma.includes('extends r12'));
const mn = R('MissingNativeLibraryActivity.java');
t('MissingNativeLibrary dialog', mn.includes('missing_native_library'));
const ar = R('AppUpgradeReceiver.java');
t('AppUpgradeReceiver BroadcastReceiver', ar.includes('extends BroadcastReceiver'));
t('AppUpgrade goAsync', ar.includes('goAsync'));
const asu = R('initializers/AppStartupInitializer.java');
t('AppStartupInitializer g06', asu.includes('implements g06'));
const li = R('initializers/LoggingInitializer.java');
t('LoggingInitializer g06+backend_override', li.includes('implements g06') && li.includes('backend_override'));
const cp = R('initializers/AppStartupInitializer.java');
t('AppStartup create(Context) NbApplication', cp.includes('NbApplication') && cp.includes('create(Context'));
t('initializers dir', X('initializers/AppStartupInitializer.java') && X('initializers/LoggingInitializer.java'));
console.log('app-shell replay: ' + n + '/10 checks green');
