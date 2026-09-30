// Phase 1147 — ly3/s06/m4d entity-store values + 4-map taxonomy
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const ly3 = R('ly3'), s06 = R('s06'), m4d = R('m4d');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ly3 extends qg2', ly3.includes('interface ly3 extends qg2'));
t('s06 implements yy3,be5,ly3,bf0', s06.includes('implements yy3, be5, ly3, bf0'));
t('s06 EMPTY k11 n', s06.includes('static final k11 n = new k11()'));
t('s06 uq9 create-op field', s06.includes('final uq9 b'));
t('s06 dual k11 h,i bounds', s06.includes('final k11 h') && s06.includes('final k11 i'));
t('s06 v09 m kind', s06.includes('final v09 m'));
t('s06 payload parts dm2/d16/z4/pp7', s06.includes('dm2 c') && s06.includes('d16 d') && s06.includes('z4 e') && s06.includes('pp7 f'));
t('s06 9-arg ctor', s06.includes('s06(uq9 uq9Var, dm2 dm2Var'));
t('m4d extends ly3', m4d.includes('interface m4d extends ly3'));
t('s06 Integer l mutable sub-idx', s06.includes('Integer l'));
console.log('entity-stores replay: ' + n + '/10 checks green');
