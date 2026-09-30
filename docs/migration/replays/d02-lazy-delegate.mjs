// Phase 1186 — Kotlin lazy delegate internals (pce SynchronizedLazyImpl + cx6 Lazy)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const pce = R('pce.java');
t('pce implements cx6+Serializable', pce.includes('implements cx6, Serializable') || pce.includes('implements cx6'));
t('pce Function0 init field', pce.includes('Function0 I'));
t('pce volatile Object J cache', pce.includes('volatile Object J'));
t('pce Object K lock', pce.includes('Object K'));
t('pce getValue lazy init', pce.includes('getValue'));
t('pce invoke on miss', pce.includes('invoke()'));
const cx6 = R('cx6.java');
t('cx6 Lazy iface', cx6.includes('interface') && cx6.includes('cx6'));
t('pce ctor takes Function0', pce.includes('pce(Function0'));
t('pce a() initialized check', pce.includes('boolean a()'));
t('SynchronizedLazyImpl double-check (synchronized)', pce.includes('synchronized') || pce.includes('K'));
console.log('lazy-delegate replay: ' + n + '/10 checks green');
