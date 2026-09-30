// Phase 1246 — wj8/w7d SharedFlow event bus
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const wj8 = R('wj8.java');
t('wj8 v7d channel', wj8.includes('v7d a = w7d.b(0, 16, w41.J, 1)'));
t('wj8 a() emit suspend', wj8.includes('a.emit(t76Var'));
t('wj8 b() tryEmit', wj8.includes('boolean b(t76 t76Var)'));
const w7d = R('w7d.java');
t('w7d NO_VALUE sentinel', w7d.includes('NO_VALUE'));
t('w7d a(i,i2,w41) factory', w7d.includes('v7d a(int i, int i2, w41 w41Var)'));
t('w7d extraBufferCapacity guard', w7d.includes('extraBufferCapacity cannot be negative'));
t('w7d b() synthetic', w7d.includes('v7d b(int i, int i2, w41'));
t('w7d d() transform', w7d.includes('ml4 d('));
const w41 = R('w41.java');
t('w41 enum I,J,K', w41.includes('w41 I') && w41.includes('w41 J') && w41.includes('w41 K'));
t('wj8 DROP_OLDEST w41.J', wj8.includes('w41.J'));
console.log('event-bus replay: ' + n + '/10 checks green');
