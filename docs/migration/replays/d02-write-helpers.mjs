// Phase 1098 — FB write helpers + ybg.c ValidationException
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const sg5 = R('sg5'), rh8 = R('rh8'), ybg = R('ybg');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('sg5.f(a,exc)→int struct write', sg5.includes('int f(a aVar, exc excVar)'));
t('sg5.f: 12-byte exc {C,a1,m}', sg5.includes('t(4, 12)') && sg5.includes('w(iC)') && sg5.includes('w(iA1)') && sg5.includes('y(sM)'));
t('sg5.f: s(2)+r() offset', sg5.includes('s(2)') && sg5.includes('aVar.r()'));
t('rh8.O(qo5,a)→int struct write', rh8.includes('int O(qo5 qo5Var, a aVar)'));
t('rh8.O: 8-byte opId {d,c}', rh8.includes('t(4, 8)') && rh8.includes('w(iD)') && rh8.includes('y(sC)'));
t('rh8.b(int,short)→qo5 ctor', rh8.includes('qo5 b(int i, short s)'));
t('ybg.c(ka4) validate+throw', ybg.includes('void c(ka4 ka4Var)') && ybg.includes('ka4Var.a()'));
t('ybg.d: MODEL log + ValidationException', ybg.includes('a.c(yn7.MODEL') && ybg.includes('new ValidationException(str)'));
t('ybg.c: null error → return', ybg.includes('strA == null'));
t('sg5.g(List)→ix4 optional list', sg5.includes('ix4 g(List list)'));
console.log('write-helpers replay: ' + n + '/10 checks green');
