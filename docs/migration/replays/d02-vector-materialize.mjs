// Phase 1095 — lv2.S/I/T vector-materialize helpers
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const lv2 = R('lv2');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('lv2.S(je8)→List<ie8>', lv2.includes('List S(je8 je8Var)'));
t('S: j()=count', lv2.includes('int iJ = je8Var.j()'));
t('S: empty→hw3.I', lv2.includes('if (iJ <= 0)') && lv2.includes('return hw3.I'));
t('S: m18.S() persistent builder', lv2.includes('m18.S()'));
t('S: per-index bind k(ie8,i)', lv2.includes('je8Var.k(ie8Var, i2)'));
t('S: m18.E freeze→List', lv2.includes('m18.E(th7VarS)'));
t('lv2.I(s83)→th7 DELETE list', lv2.includes('th7 I(s83 s83Var)'));
t('lv2.T(r29)→List bundle ops', lv2.includes('List T(r29 r29Var)'));
t('S: new ie8() reusable elem', lv2.includes('new ie8()'));
t('S: loop 0..n', lv2.includes('i2 < iJ'));
console.log('vector-materialize replay: ' + n + '/10 checks green');
