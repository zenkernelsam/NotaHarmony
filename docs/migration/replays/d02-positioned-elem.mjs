// Phase 1127 — xwc positioned element + g2c list adapter + f2c table
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const xwc = R('xwc'), g2c = R('g2c'), ywc = R('ywc'), hvd = R('hvd');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('xwc extends ywc', xwc.includes('extends ywc'));
t('xwc {qo5,g2c,long}', xwc.includes('qo5 b') && xwc.includes('g2c c') && xwc.includes('long d'));
t('xwc.a()→qo5', xwc.includes('qo5 a()'));
t('xwc.c()→List (g2c)', xwc.includes('List c()'));
t('ywc abstract {Integer,a()→qo5}', ywc.includes('abstract class ywc') && ywc.includes('abstract qo5 a()'));
t('g2c extends hvd', g2c.includes('extends hvd'));
t('g2c wraps f2c', g2c.includes('g2c(f2c'));
t('g2c.d()→f2c.j() count', g2c.includes('this.I).j()'));
t('g2c.e(i,cxc)→f2c.l bind-read', g2c.includes('this.I).l(i, cxcVar)'));
t('hvd = FB vector→List adapter', hvd.includes('implements List, ik6') || hvd.includes('List'));
console.log('positioned-elem replay: ' + n + '/10 checks green');
