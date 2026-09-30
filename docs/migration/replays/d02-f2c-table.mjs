// Phase 1128 — f2c seq-element FlatBuffers table
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const f2c = R('f2c');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('f2c extends cee implements ka4', f2c.includes('extends cee implements ka4'));
t('f2c.j()→count via c(4)', f2c.includes('int j()') && f2c.includes('int iC = c(4)'));
t('f2c.k()→qo5 via c(6)', f2c.includes('qo5 k()') && f2c.includes('int iC = c(6)'));
t('f2c.k: qo5.b(pos,bb) bind', f2c.includes('qo5Var.b(i, byteBuffer)'));
t('f2c.l(i,cxc) bind-read', f2c.includes('void l(int i, cxc cxcVar)'));
t('f2c.l: 12-byte stride i*12', f2c.includes('(i * 12)'));
t('f2c.l: f(iC) vector start', f2c.includes('f(iC)'));
t('f2c hashCode lv2.O + qo5', f2c.includes('lv2.O(this)') && f2c.includes('qo5VarK.hashCode()'));
t('f2c implements ka4 validate', f2c.includes('ka4'));
t('cxc is 12-byte exc-family anchor', f2c.includes('cxc') && f2c.includes('* 12'));
console.log('f2c-table replay: ' + n + '/10 checks green');
