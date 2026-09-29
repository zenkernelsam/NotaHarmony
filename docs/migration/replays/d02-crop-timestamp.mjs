// Phase 1082 — do6.i page-crop via tz9 + nti.y serverTime
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const do6 = R('do6'), nti = R('nti'), tz9 = R('tz9'), xgb = R('xgb');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('do6.i: page→crop via tz9 key', do6.includes('Object i(cxc cxcVar, Map map)') && do6.includes('new tz9(cxcVar)'));
t('do6.i: map.get', do6.includes('map.get(new tz9'));
t('tz9: cxc page-ref', tz9.includes('cxc a'));
t('nti.y(uq9)→xgb', nti.includes('xgb y(uq9 uq9Var)'));
t('nti.y: op.j()→tmf serverTime', nti.includes('tmf tmfVarJ = uq9Var.j()'));
t('nti.y: null-safe → new xgb(I)', nti.includes('new xgb(tmfVarJ.I)') && nti.includes('return null'));
t('xgb: timestamp holder', xgb.length > 0);
t('fsi.J vs nti.y: serverTime-fallback vs strict', R('fsi').includes('tmfVarN.I : uq9Var.k()'));
t('do6.g: builder-init (Phase 1065)', do6.includes('fqb g(yc6 yc6Var, yc6 yc6Var2)'));
t('tz9 equals for map key', tz9.includes('equals') || tz9.includes('a ='));
console.log('crop-timestamp replay: ' + n + '/10 checks green');
