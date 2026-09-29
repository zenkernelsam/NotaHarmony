// Phase 1074 — ie8 transform item + yy3/xy3 snapshot cycle
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const ie8 = R('ie8'), yy3 = R('yy3'), xy3 = R('xy3');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ie8 extends cee + ka4', ie8.includes('extends cee implements ka4'));
t('ie8.a()→ddg.e validation', ie8.includes('ddg.e(this)'));
t('ie8.j()→fqa origin', ie8.includes('fqa j()'));
t('ie8.k()→cxc page', ie8.includes('cxc k()'));
t('ie8.l()→k2d scale + m()→y2d rot', ie8.includes('k2d l()') && ie8.includes('y2d m()'));
t('ie8.n()→qo5 entityId + o()→tmf zIndex', ie8.includes('qo5 n()') && ie8.includes('tmf o()'));
t('yy3 extends ly3,qg2', yy3.includes('extends ly3, qg2'));
t('yy3: E() + builder()→xy3', yy3.includes('int E()') && yy3.includes('xy3 builder()'));
t('xy3.build()→yy3 (cycle)', xy3.includes('yy3 build()'));
t('ie8 equals on 6 fields', ie8.includes('n().equals') && ie8.includes('ba6.o'));
console.log('transform-item replay: ' + n + '/10 checks green');
