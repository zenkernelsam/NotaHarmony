// Phase 1115 — kci.b op-table build recipe + dbj.c + MP3 tables
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const kci = R('kci'), dbj = R('dbj');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('kci.b(exc,String,qo5)→f46', kci.includes('f46 b(exc excVar, String str, qo5 qo5Var)'));
t('kci.b: dk4.a pooled builder', kci.includes('dk4.a(c8dVar)'));
t('kci.b: dbj.c createString', kci.includes('dbj.c(str, aVarA)'));
t('kci.b: startTable(3) C(3)', kci.includes('aVarA.C(3)'));
t('kci.b: h(1,iC) string field', kci.includes('aVarA.h(1, iC)'));
t('kci.b: j(0,sg5.f exc) anchor', kci.includes('aVarA.j(0, sg5.f(aVarA, excVar))'));
t('kci.b: j(2,rh8.O opId)', kci.includes('aVarA.j(2, rh8.O(qo5Var, aVarA))'));
t('kci.b: n() end + z + p finish', kci.includes('int iN = aVarA.n()') && kci.includes('aVarA.z(iN, 6)') && kci.includes('aVarA.p(iN)'));
t('kci.b: bind + validate + recycle', kci.includes('f46Var.d(byteBufferWrap.getInt') && kci.includes('ybg.c(f46Var)') && kci.includes('rh8.q(c8dVar, null)'));
t('kci MP3 tables', kci.includes('8000') && kci.includes('44100') && kci.includes('int[]'));
console.log('op-build replay: ' + n + '/10 checks green');
