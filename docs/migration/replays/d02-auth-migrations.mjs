// Phase 1023 — auth DataStore migrations (prf/qrf) + hq8/eua
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const hq8 = readFileSync(D + 'hq8.java', 'utf8');
const eua = readFileSync(D + 'eua.java', 'utf8');
const prf = readFileSync(D + 'prf.java', 'utf8');
const qrf = readFileSync(D + 'qrf.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('hq8: datastore base', /abstract class hq8/.test(hq8) && hq8.includes('CountDownLatch'));
t('eua: Key name+hash', /public final String a;/.test(eua) && eua.includes('equals') && eua.includes('hashCode'));
t('prf: bt2 migration', /class prf implements bt2/.test(prf));
t('prf: emailHash key', prf.includes('new eua("currentUserEmailHash")'));
t('prf: v1→v2 purge', prf.includes('tk8VarC.f(xrf.l)') && prf.includes('tk8VarC.f(xrf.m)') && prf.includes('new Integer(2)'));
t('prf: applies when dv<2', prf.includes('num.intValue() : 0) < 2'));
t('qrf: bt2 migration', /class qrf implements bt2/.test(qrf));
t('qrf: v2→v3', qrf.includes('new Integer(3)'));
t('qrf: email regex', qrf.includes('email') && qrf.includes('Pattern.compile'));
t('qrf: iterates emailToDeviceIds', qrf.includes('xrf.m'));
const xrf = readFileSync(D + 'xrf.java', 'utf8');
t('xrf: m0(prf,qrf) chain', xrf.includes('m18.m0(new prf(), new qrf())'));
console.log('auth-migrations replay: ' + n + '/11 checks green');
