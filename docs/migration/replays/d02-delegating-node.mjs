// Phase 1252 — n73 DelegatingNode
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const n73 = R('n73.java');
t('n73 extends od8', n73.includes('extends od8'));
t('n73 W=ty8.e(this) aggregate', n73.includes('ty8.e(this)'));
t('n73 X delegate chain', n73.includes('od8 X'));
t('n73 g1(j73) delegate', n73.includes('j73 g1(j73 j73Var)'));
t('n73 already-delegated guard', n73.includes('Cannot delegate to an already delegated node'));
t('n73 already-attached guard', n73.includes('Cannot delegate to an already attached node'));
t('n73 ty8.f kind-mask', n73.includes('ty8.f(od8VarN0)'));
t('n73 multiple-LayoutNode guard', n73.includes('Delegating to multiple LayoutModifierNodes'));
t('n73 ty8.a attach', n73.includes('ty8.a(od8VarN0, -1, 1)'));
t('n73 h1(j73) undelegate', n73.includes('h1(j73 j73Var)'));
console.log('delegating-node replay: ' + n + '/10 checks green');
