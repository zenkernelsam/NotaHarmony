// Phase 1241 — k2/bk5/j2 editor Modifier.Node family
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const k2 = R('k2.java');
t('k2 extends n73 8 ifaces', k2.includes('extends n73 implements ara, jm6, mvc, vff, q52, sn9, pz5, b25'));
t('k2 bq4 f0 focus relay', k2.includes('new bq4(wj8Var'));
t('k2 fwa long-press emit', k2.includes('new fwa(this.m0)'));
t('k2 wj8.b(sj5)', k2.includes('wj8Var.b(new sj5(rj5Var))'));
t('k2 H(KeyEvent)', k2.includes('boolean H(KeyEvent'));
t('k2 h(xvc) semantics', k2.includes('void h(xvc'));
const j2 = R('j2.java');
t('j2 coroutine rj5+sj5', j2.includes('new rj5()') && j2.includes('new sj5(rj5Var'));
const bk5 = R('bk5.java');
t('bk5 extends od8 ara', bk5.includes('extends od8 implements ara'));
t('bk5 A(iqa,jqa,long) input', bk5.includes('A(iqa iqaVar, jqa jqaVar, long'));
t('bk5 i1 sj5 cleanup', bk5.includes('i1()') && bk5.includes('new sj5(rj5Var'));
console.log('editor-nodes replay: ' + n + '/10 checks green');
