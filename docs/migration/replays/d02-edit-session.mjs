// Phase 1245 — ll3/ml3 edit-session boundary events
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const qle = R('qle.java'), vle = R('vle.java');
t('qle emits ll3', qle.includes('new ll3()'));
t('qle g0.b(ll3)', qle.includes('vleVar.g0.b(ll3Var)'));
t('qle k0=ll3 current', qle.includes('vleVar.k0 = ll3Var'));
t('vle l1() session end', vle.includes('public final void l1()'));
t('vle ml3{k0}', vle.includes('new ml3(ll3Var)'));
t('vle k0 null-guard', vle.includes('if (ll3Var != null)') || vle.includes('k0 != null'));
t('vle k0=null after', vle.includes('this.k0 = null'));
const ml3 = R('ml3.java');
t('ml3{ll3 a}', ml3.includes('final ll3 a'));
const ll3 = R('ll3.java');
t('ll3 singleton t76', ll3.includes('implements t76'));
t('vle g0=wj8 channel', vle.includes('this.g0.b('));
console.log('edit-session replay: ' + n + '/10 checks green');
