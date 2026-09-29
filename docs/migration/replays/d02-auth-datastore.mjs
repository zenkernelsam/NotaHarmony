// Phase 1020 — xrf auth DataStore
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const xrf = readFileSync(D + 'xrf.java', 'utf8');
const hq8 = readFileSync(D + 'hq8.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('xrf extends hq8', xrf.includes('extends hq8'));
t('key: dataVersion', xrf.includes('new eua("dataVersion")'));
t('key: authToken', xrf.includes('new eua("authToken")'));
t('key: emailToDeviceIds', xrf.includes('new eua("emailToDeviceIds")'));
t('key: currentUserEmail', xrf.includes('new eua("currentUserEmail")'));
t('key: currentUserId', xrf.includes('new eua("currentUserId")'));
t('migration list', xrf.includes('m18.m0(new prf(), new qrf())'));
t('4 lazy pce getters', (xrf.match(/public final pce [g-j];/g) || []).length === 4);
t('Context ctor', xrf.includes('public xrf(Context context)'));
t('hq8 = datastore base', /class hq8|interface hq8/.test(hq8));
console.log('auth-datastore replay: ' + n + '/10 checks green');
