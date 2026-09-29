// Phase 1108 — njj.L/M/y + xj2.f/g + njj.z helpers
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const njj = R('njj'), xj2 = R('xj2');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('njj.L(jxc,exc) membership', njj.includes('boolean L(jxc jxcVar, exc excVar)'));
t('njj.L: map-TRUE vs set-contains', njj.includes('jxcVar.f().get(excVar), Boolean.TRUE') && njj.includes('jxcVar.b().contains(excVar)'));
t('njj.M identity-matrix 16-float', njj.includes('fArr.length >= 16') && njj.includes('fArr[15] == 1.0f'));
t('njj.M checks m[0]=1,m[5]=1,m[10]=1', njj.includes('fArr[0] == 1.0f') && njj.includes('fArr[5] == 1.0f') && njj.includes('fArr[10] == 1.0f'));
t('njj.y = x(Q(jxc,exc)) pos chain', njj.includes('x(jxcVar, Q(jxcVar, excVar))'));
t('njj.O optional rwc (i&4)', njj.includes('qwc O(jxc') && njj.includes('(i & 4) != 0'));
t('xj2.f map-get + bl2 unwrap', xj2.includes('map.get(obj)') && xj2.includes('bl2') && xj2.includes('.c'));
t('xj2.g float-pair unpack >>32', xj2.includes('>> 32') && xj2.includes('intBitsToFloat'));
t('njj.z last_insert_rowid', njj.includes('SELECT last_insert_rowid()'));
t('njj.z rh8.q close', njj.includes('rh8.q(z7cVarD1, null)'));
console.log('seq-helpers replay: ' + n + '/10 checks green');
