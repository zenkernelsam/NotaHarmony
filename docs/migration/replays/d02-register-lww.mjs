// Phase 1063 — Register LWW (fqb/yc6) + so5 opId order + fsi.J
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const fqb = R('fqb'), so5 = R('so5'), fsi = R('fsi'), yc6 = R('yc6');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('fqb: fields {qo5 a, Object b, xgb c}', fqb.includes('public qo5 a') && fqb.includes('public Object b') && fqb.includes('public xgb c'));
t('fqb.c: LWW write on so5.a>0', fqb.includes('so5.a(qo5VarL, qo5Var) > 0') && fqb.includes('this.a = qo5VarL'));
t('fqb.c: null-current always wins', fqb.includes('qo5Var == null ||'));
t('fqb.a: snapshot→yc6', fqb.includes('new yc6(this.a, this.b, this.c'));
t('fqb.b: isSet', fqb.includes('return this.a != null'));
t('so5.a: unsigned lt then site', so5.includes('Integer.compareUnsigned(qo5Var.d(), qo5Var2.d())') && so5.includes('ba6.w(qo5Var.c() & 65535'));
t('fsi.J: serverTime ?: clientTime', fsi.includes('tmfVarN.I : uq9Var.k()') && fsi.includes('tmfVarN != null'));
t('yc6: register snapshot holder {J,K,L} + ctor-14', yc6.includes('public Object J') && yc6.includes('public Object K') && fqb.includes('this.c, 14'));
t('fqb ctor from yc6', fqb.includes('fqb(yc6 yc6Var)') && fqb.includes('yc6Var.J'));
t('fqb: timestamp via xgb(J)', fqb.includes('new xgb(J)'));
t('qo5: c()=site d()=time', R('qo5').includes('extends xwd'));
console.log('register-lww replay: ' + n + '/11 checks green');
