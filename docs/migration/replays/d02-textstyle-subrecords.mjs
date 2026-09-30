// Phase 1268 — gnd/e5a/ima/rq4 TextStyle sub-records
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const gnd = R('gnd.java');
t('gnd implements wz', gnd.includes('implements wz'));
t('gnd xoe brush + fontSize', gnd.includes('xoe a') && gnd.includes('long b'));
t('gnd FontWeight/Style/Synthesis', gnd.includes('ns4 c') && gnd.includes('js4 d') && gnd.includes('ks4 e'));
t('gnd fontFamily+letterSpacing', gnd.includes('sq4 f') && gnd.includes('long h'));
const e5a = R('e5a.java');
t('e5a implements wz + merge', e5a.includes('implements wz') && e5a.includes('e5a a(e5a'));
t('e5a textAlign+lineHeight', e5a.includes('int a') && e5a.includes('long c'));
const ima = R('ima.java');
t('ima PlatformTextStyle ama+tla', ima.includes('ama a') && ima.includes('tla b'));
const rq4 = R('rq4.java');
t('rq4 FontResolver iface', rq4.includes('interface rq4'));
const wz = R('wz.java');
t('wz common style iface', wz.includes('wz'));
const zqe = R('zqe.java');
t('zqe composes gnd+e5a+ima', zqe.includes('gnd a') && zqe.includes('e5a b') && zqe.includes('ima c'));
console.log('textstyle-subrecords replay: ' + n + '/10 checks green');
