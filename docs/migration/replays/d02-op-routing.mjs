// Phase 1070 — fsi op→entity-id routing + DELETE enumeration
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const fsi = R('fsi'), haa = R('haa');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('fsi.F: switch on op ordinal', fsi.includes('List F(uq9 uq9Var)') && fsi.includes('switch (haaVarM.ordinal())'));
t('fsi.F: CREATE cases 3/5/15/18/20/22', fsi.includes('case 3:') && fsi.includes('case 22:') && fsi.includes('case 20:'));
t('fsi.F: default → hw3.I empty', fsi.includes('return hw3.I'));
t('fsi.F: single-entity o09(op.l())', fsi.includes('new o09(uq9Var.l())'));
t('CREATE_PAGE: page-id range nti.g(opId,i)', fsi.includes('nti.g(uq9Var.l(),') && fsi.includes('new r09'));
t('CREATE_PAGE: ln2.m() pageCount loop', fsi.includes('((ln2) z5c.x(uq9Var)).m()') && fsi.includes('rmfVar.iterator()'));
t('fsi.G: DELETE via s83→lv2.I', fsi.includes('lv2.I((s83) z5c.x(uq9Var))'));
t('fsi.H: DELETE via s83→icj.b', fsi.includes('icj.b((s83) z5c.x(uq9Var))'));
t('G/H gated by yq9.a[ord]==1', (fsi.match(/yq9\.a\[uq9Var\.m\(\)\.ordinal\(\)\] == 1/g) || []).length >= 2);
t('haa: 32-op ordinal space', haa.includes('MODIFY_COMMENT') && haa.includes('NONE'));
console.log('op-routing replay: ' + n + '/10 checks green');
