// Phase 1035 — Kotlin coroutine primitives (sfb/ml4/em8/fm8)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const sfb = readFileSync(D + 'sfb.java', 'utf8');
const em8 = readFileSync(D + 'em8.java', 'utf8');
const fm8 = readFileSync(D + 'fm8.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('sfb: MutableSharedFlow impl', sfb.includes('implements s7d, ml4, cz4'));
t('sfb: v7d delegate', /public final .*\bv7d I;/.test(sfb) || sfb.includes('v7d v7dVar'));
t('sfb: b()→ml4 collect', sfb.includes('public final ml4 b('));
t('em8: Mutex', em8.includes('extends bwc') && em8.includes('implements cm8'));
t('em8: owner CAS', em8.includes('AtomicReferenceFieldUpdater') && em8.includes('owner$volatile'));
t('fm8: a()→em8 factory', fm8.includes('public static em8 a()'));
t('fm8: NO_OWNER sentinel', fm8.includes('new f02("NO_OWNER"'));
// s7d = parent of ml4
const s7d = readFileSync(D + 's7d.java', 'utf8');
t('s7d: flow iface', /interface s7d|class s7d/.test(s7d));
// cz4 = collector
const cz4 = readFileSync(D + 'cz4.java', 'utf8');
t('cz4: collector iface', /interface cz4|class cz4/.test(cz4));
const b50 = readFileSync(D + 'b50.java', 'utf8');
t('b50 uses fm8 Mutex', b50.includes('fm8.a()'));
console.log('coroutine-primitives replay: ' + n + '/10 checks green');
