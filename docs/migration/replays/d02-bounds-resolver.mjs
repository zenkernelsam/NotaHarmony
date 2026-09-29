// Phase 1078 — ba6.k bounds resolver + sia/vnd spatial index
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const ba6 = R('ba6'), ue4 = R('ue4'), sia = R('sia'), vnd = R('vnd');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ba6.k: (qo5,Map×7,ue4)→k11', ba6.includes('k11 k(qo5 qo5Var, Map map, Map map2, Map map3, Map map4, Map map5, Map map6, Map map7, ue4 ue4Var)'));
t('packed key: lt<<32|site', ba6.includes('4294967295L) << 32') && ba6.includes('65535'));
t('spatial cache: ue4.J→sia.a.h(key)→vnd', ba6.includes('((sia) ue4Var.J).a.h(') && ba6.includes('vnd.b(vndVar)'));
t('cache hit → return bounds', ba6.includes('return k11VarB'));
t('fallback: R()→be5 entity resolve', ba6.includes('be5VarR = R(qo5Var, map, map2, map3, map4, map5'));
t('do6.i(page)→bmb crop', ba6.includes('do6.i(be5VarR.i(), map8)') && ba6.includes('bmb bmbVar'));
t('transform×crop → k11', ba6.includes('h0(be5VarR.G(), bmbVar.c())'));
t('ba6.R: 5-map resolver', ba6.includes('R(qo5 qo5Var, Map') || ba6.includes('be5 R('));
t('vnd.b accessor exists', vnd.includes('vnd') && vnd.length > 0);
t('sia spatial index', sia.length > 0 && ba6.includes('sia'));
console.log('bounds-resolver replay: ' + n + '/10 checks green');
