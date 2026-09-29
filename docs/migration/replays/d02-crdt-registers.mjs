// Phase 1062 — CRDT register apply layer (fi0/rz1/fqb/be5)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const fi0 = R('fi0'), rz1 = R('rz1'), be5 = R('be5');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('fi0.d: register-apply template', fi0.includes('void d(uq9') && fi0.includes('ie8'));
t('fi0: pageAndOrigin register (k1a+tz9)', fi0.includes('pageAndOriginRegister') && fi0.includes('k1a') && fi0.includes('tz9'));
t('fi0: rotation/scale/zIndex registers', fi0.includes('rotationRegister') && fi0.includes('scaleRegister') && fi0.includes('zIndexRegister'));
t('fi0: rz1.R/P/Q dispatch', fi0.includes('rz1.R(') && fi0.includes('rz1.P(') && fi0.includes('rz1.Q('));
t('fi0: xgb ULong wrap + A() invalidate', fi0.includes('new xgb(tmfVarO.I)') && fi0.includes('A()'));
t('fi0: real Register$Builder name', fi0.includes('Register$Builder'));
t('rz1.R: null-skip + fqb.c(op,val)', rz1.includes('boolean R(v1b') && rz1.includes('((fqb) v1bVar.get()).c(uq9Var, obj)') && rz1.includes('return false'));
t('rz1.P/Q: SetFloat/scale specializations', rz1.includes('boolean P(v1b v1bVar, uq9 uq9Var, k2d') && rz1.includes('boolean Q(v1b v1bVar, uq9 uq9Var, y2d'));
t('be5: transform iface {G,b,h,i,j}', be5.includes('k11 G()') && be5.includes('qed b()') && be5.includes('fqa h()') && be5.includes('cxc i()') && be5.includes('Float j()'));
t('be5.P: matrix build (y18.l/h/i)', be5.includes('y18.l(fArrA') && be5.includes('y18.h(') && be5.includes('y18.i(fArrA'));
t('be5 implementors m5d/ry0', R('m5d').includes('implements be5') && R('ry0').includes('implements be5'));
console.log('crdt-registers replay: ' + n + '/11 checks green');
