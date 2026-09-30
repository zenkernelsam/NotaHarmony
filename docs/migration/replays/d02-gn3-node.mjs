// Phase 1242 — gn3 editor Node (mn3->nn3/ln3 dual end)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const gn3 = R('gn3.java');
t('gn3 extends n73 4 ifaces', gn3.includes('extends n73 implements ara, pz5, q52, b25'));
t('gn3 new mn3()', gn3.includes('new mn3()'));
t('gn3 nn3 end-A', gn3.includes('new nn3(mn3Var'));
t('gn3 ln3 end-B', gn3.includes('new ln3(mn3Var'));
t('gn3 m1->wj8.b(ln3)', gn3.includes('m1()') && gn3.includes('wj8Var.b(new ln3(mn3Var))'));
t('gn3 A1 pointer lifecycle', gn3.includes('void A1('));
t('gn3 p1(oqa,long,bv0)', gn3.includes('p1(oqa'));
t('gn3 x1 drag 2-pointer', gn3.includes('x1(oqa oqaVar, oqa oqaVar2, long'));
t('gn3 a0(oqa) predicate', gn3.includes('a0(oqa'));
t('gn3 wj8 channel emit', gn3.includes('wj8Var.b('));
console.log('gn3-node replay: ' + n + '/10 checks green');
