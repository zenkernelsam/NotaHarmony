// Phase 1220 — a46 InputTransformation chain (bg4.then / d28.maxLength / nv1 hex)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const a46 = R('a46.java');
t('a46 iface i(dle)+j()->nn6', a46.includes('void i(dle') && a46.includes('nn6 j()'));
const bg4 = R('bg4.java');
t('bg4 .then chain', bg4.includes('.then(') && bg4.includes('this.b.i(dleVar)'));
t('bg4 j merges nn6', bg4.includes('nn6VarJ.b('));
const d28 = R('d28.java');
t('d28 maxLength(6) toString', d28.includes('InputTransformation.maxLength(6)'));
t('d28 revert on overflow', d28.includes('dleVar.c(0, length, eleVar.K.toString())') && d28.includes('dleVar.a().w()'));
const nv1 = R('nv1.java');
t('nv1 hex # prefix', nv1.includes("charAt(0) == '#'"));
t('nv1 hex charset check', nv1.includes("'0' > cCharAt") && nv1.includes("'g'") && nv1.includes("'G'"));
t('z36 empty transform', R('z36.java').includes('void i(dle'));
t('a46 default j()->null', a46.includes('return null'));
t('bg4+nv1+d28+z36 implement a46', ['bg4','nv1','d28','z36'].every(f=>R(f+'.java').includes('implements a46')));
console.log('a46-input-transformation replay: ' + n + '/10 checks green');
