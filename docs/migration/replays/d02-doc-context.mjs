// Phase 1086 — v69 context deps: ny3 bounds svc + al2 tombstone + jm5
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const v69 = R('v69'), ny3 = R('ny3'), al2 = R('al2'), jm5 = R('jm5');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('v69: ny3 c bounds svc + jm5 d', v69.includes('ny3 c') && v69.includes('jm5 d'));
t('ny3: a(qo5,int,k11) set bounds', ny3.includes('void a(qo5 qo5Var, int i, k11 k11Var)'));
t('ny3: e(qo5,int)→k11 get bounds', ny3.includes('k11 e(qo5 qo5Var, int i)'));
t('al2 implements Map,ik6', al2.includes('implements Map, ik6'));
t('al2: gja inner + J/L dirty sets + a2d', al2.includes('gja I') && al2.includes('Set J') && al2.includes('Set L') && al2.includes('a2d N'));
t('v69.j()→al2 tombstone map', v69.includes('al2 j()'));
t('jm5: int+Object slot holder', jm5.includes('public int b') && jm5.includes('Object c'));
t('v69.j()→al2 = ba6.K tombstone target', v69.includes('al2'));
t('v69.a→a79 constants', v69.includes('a79 a'));
t('v69.q→lia collection', v69.includes('lia q'));
console.log('doc-context replay: ' + n + '/10 checks green');
