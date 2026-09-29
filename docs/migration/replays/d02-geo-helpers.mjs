// Phase 1080 — ba6.K tombstone + h0 translate + i() rect-rotate
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const ba6 = R('ba6');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ba6.K: tombstone = o(get,TRUE)', ba6.includes('boolean K(qo5 qo5Var, Map map)') && ba6.includes('o(map.get(qo5Var), Boolean.TRUE)'));
t('h0: translate bounds by fqa', ba6.includes('k11 h0(k11 k11Var, fqa fqaVar)') && ba6.includes('k11Var.a + fC'));
t('i: rect-rotate signature (cmb,w,h,deg)', ba6.includes('cmb i(cmb cmbVar, float f, float f2, int i)'));
t('i: deg 0 → unchanged', ba6.includes('if (i == 0)') && ba6.includes('return cmbVar'));
t('i: deg 90 swap', ba6.includes('if (i == 90)') && ba6.includes('f2 - cmbVar.c'));
t('i: deg 180', ba6.includes('if (i == 180)') && ba6.includes('f - f5'));
t('i: deg 270', ba6.includes('if (i == 270)') && ba6.includes('f - f7'));
t('i: unsupported → telemetry', ba6.includes('Unsupported PDF rotation') && ba6.includes('rotation.deg'));
t('i: telemetry → return unchanged (fail-soft)', ba6.includes('yn7.RENDERER'));
t('cmb rect type', R('cmb').length > 0);
console.log('geo-helpers replay: ' + n + '/10 checks green');
