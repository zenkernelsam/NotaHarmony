// Phase 1065 — n5d spec from CREATE-op + do6.g init + convergence
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const n5d = R('n5d'), do6 = R('do6'), m5d = R('m5d'), fqb = R('fqb');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('n5d: implements yy3,bf0,be5,m4d', n5d.includes('implements yy3, bf0, be5, m4d'));
t('n5d: 14 yc6 register snapshots', (n5d.match(/public final yc6 [a-z];/g) || []).length >= 14);
t('n5d ctor: from uq9 + ao2 payload', n5d.includes('n5d(uq9 uq9Var, ao2 ao2Var'));
t('n5d: b = create op (O() provenance)', n5d.includes('this.b = uq9Var') && n5d.includes('uq9 O()'));
t('n5d: timestamp nti.y ?: k()', n5d.includes('nti.y(uq9Var)') && n5d.includes('uq9Var.k()'));
t('do6.g: ignores arg1 → new fqb(arg2)', do6.includes('fqb g(yc6 yc6Var, yc6 yc6Var2)') && do6.includes('return new fqb(yc6Var2)'));
t('m5d ctor: n5d.e..r → do6.g per reg', m5d.includes('n5dVar.e') && m5d.includes('n5dVar.r'));
t('fqb.c: the merge = LWW op-write', fqb.includes('so5.a(qo5VarL, qo5Var) > 0'));
t('n5d: be5 impl (spec as transform source)', n5d.includes('be5'));
t('n5d: holds xgb + m4c non-reg fields', n5d.includes('xgb xgbVar') && n5d.includes('m4c m4cVar'));
console.log('spec-create replay: ' + n + '/10 checks green');
