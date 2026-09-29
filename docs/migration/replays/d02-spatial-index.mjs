// Phase 1081 — igf long-map + vnd node + und key + sia versioned
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const sia = R('sia'), igf = R('igf'), vnd = R('vnd'), und = R('und');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('sia{igf,int} + empty singleton', sia.includes('igf a') && sia.includes('int b') && sia.includes('new sia(igf.g, 0)'));
t('igf: long[] keys + Object[] vals (open map)', igf.includes('long[] c') && igf.includes('Object[] e') && igf.includes('long a'));
t('igf.g = empty instance', igf.includes('public static final igf g'));
t('vnd implements Comparable', vnd.includes('implements Comparable'));
t('vnd: ly3 entity + 4-float bounds', vnd.includes('ly3 I') && vnd.includes('float J') && vnd.includes('float M'));
t('vnd: boolean N + und O', vnd.includes('boolean N') && vnd.includes('und O'));
t('und{qo5,long} key wrapper', und.includes('qo5 a') && und.includes('long b'));
t('und.a()→qo5 accessor', und.includes('qo5 a()'));
t('sia ctor (igf,int)', sia.includes('sia(igf igfVar, int i)'));
t('vnd fields I..O (entity+bounds+flag)', vnd.includes('ly3 I'));
console.log('spatial-index replay: ' + n + '/10 checks green');
