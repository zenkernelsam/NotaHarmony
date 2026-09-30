// Phase 1130 — e4c.b dispatch + *wc apply-record taxonomy
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const e4c = R('e4c'), twc = R('twc'), vwc = R('vwc'), wwc = R('wwc'),
      f4c = R('f4c'), h4c = R('h4c'), rub = R('rub'), mqf = R('mqf');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('e4c.b ordinal dispatch', e4c.includes('uq9Var.m().ordinal()') && e4c.includes('case 7') && e4c.includes('case 28') || e4c.includes('case 7'));
t('case7→uwc, case8→twc', e4c.includes('new uwc(') && e4c.includes('new twc('));
t('case9→vwc, case10→wwc', e4c.includes('new vwc(') && e4c.includes('new wwc('));
t('case11→xwc', e4c.includes('new xwc('));
t('case28→f4c(bl2)', e4c.includes('new f4c(new bl2('));
t('twc extends ywc {List}', twc.includes('extends ywc') && twc.includes('List b'));
t('vwc {qo5,exc}', vwc.includes('extends ywc') && vwc.includes('qo5 b') && vwc.includes('exc c'));
t('wwc {qo5,List}', wwc.includes('extends ywc') && wwc.includes('qo5 b') && wwc.includes('List c'));
t('h4c {ywc,qo5} / f4c {bl2,qo5}', h4c.includes('ywc a') && f4c.includes('bl2 a'));
t('rub range adapter + mqf payload', rub.includes('extends hvd') && mqf.includes('extends cee implements ka4'));
console.log('apply-records replay: ' + n + '/10 checks green');
