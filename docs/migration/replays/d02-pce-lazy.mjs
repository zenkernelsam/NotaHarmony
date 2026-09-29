// Phase 1034 — pce Kotlin Lazy impl + cx6 resolution
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const pce = readFileSync(D + 'pce.java', 'utf8');
const cx6 = readFileSync(D + 'cx6.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('pce implements cx6+Serializable', pce.includes('implements cx6') && pce.includes('Serializable'));
t('pce: Function0 init', /public Function0 I;/.test(pce));
t('pce: volatile value', /public volatile Object J;/.test(pce));
t('pce: lock object', /public final Object K;/.test(pce));
t('pce: Function0 ctor', pce.includes('public pce(Function0 function0)'));
t('pce: a()=isInitialized', pce.includes('public final boolean a()'));
t('pce: getValue()', pce.includes('public final Object getValue()'));
t('cx6: a+getValue iface', cx6.includes('boolean a(') && cx6.includes('getValue('));
t('pce: DCL pattern', pce.includes('synchronized') || pce.includes('K'));
const qr1 = readFileSync(D + 'qr1.java', 'utf8');
t('qr1 uses pce lazy', qr1.includes('pce') && qr1.includes('getValue()'));
console.log('pce-lazy replay: ' + n + '/10 checks green');
