// Phase 1079 — ba6.R entity→be5 resolver + map fallback
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const ba6 = R('ba6'), s06 = R('s06'), m4d = R('m4d'), ly3 = R('ly3');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ba6.R: (qo5,5 maps,z,z2)→be5', ba6.includes('be5 R(qo5 qo5Var, Map map, Map map2, Map map3, Map map4, Map map5, boolean z, boolean z2)'));
t('ba6.R: !z2 → tombstone check K(id,map2)→null', ba6.includes('!z2 && K(qo5Var, map2)') && ba6.includes('return null'));
t('ba6.R: z → map.get→ly3→be5', ba6.includes('ly3Var instanceof be5'));
t('ba6.R: map3→s06 fallback', ba6.includes('(s06) map3.get(qo5Var)'));
t('ba6.R: map4→m4d fallback', ba6.includes('(m4d) map4.get(qo5Var)'));
t('ba6.R: map5→ly3 fallback', ba6.includes('(ly3) map5.get(qo5Var)'));
t('m4d iface exists (spec→be5)', m4d.length > 0);
t('s06 iface exists', s06.length > 0);
t('ly3 iface exists', ly3.length > 0);
t('ba6.K tombstone helper exists', ba6.includes('K(qo5 qo5Var, Map') || ba6.includes('boolean K('));
console.log('entity-resolver replay: ' + n + '/10 checks green');
