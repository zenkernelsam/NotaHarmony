// Phase 1135 — e4c delete-check / snapshot / batch-read APIs
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const e4c = R('e4c');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('e4c.A(Integer)→Boolean tombstone check', e4c.includes('Boolean A(Integer num)'));
t('e4c.A: au1.g1 pos→cursor', e4c.includes('au1.g1(num.intValue(), this.e.g)'));
t('e4c.A: xj2.f anchor→tombstone', e4c.includes('xj2.f(excVarD, this.g.I)'));
t('e4c.a()→m4c spec snapshot', e4c.includes('m4c a()') && e4c.includes('m4c.D('));
t('e4c.a: rebuild l4c from k4c', e4c.includes('new l4c(mhaVar, or5Var'));
t('e4c.a: iwc.c()→bxc + f.build + g.a', e4c.includes('bxcVarC = this.e.c()') && e4c.includes('this.f.build()') && e4c.includes('this.g.a()'));
t('e4c.f(List) runBlocking batch', e4c.includes('List f(List list)') && e4c.includes('x90.J0'));
t('e4c.f: 200ms timeout', e4c.includes('ijg.r0(200, dr3.MILLISECONDS)'));
t('e4c.h static s3c extract', e4c.includes('void h(StringBuilder sb') && e4c.includes('new s3c(set2'));
t('e4c.c()→iwc.g.d count', e4c.includes('return this.e.g.d()'));
console.log('delete-read replay: ' + n + '/10 checks green');
