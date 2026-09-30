// Phase 1191 — text-edit undo records (ele CharSequence + dle Appendable)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const ele = R('ele.java');
t('ele implements CharSequence', ele.includes('implements CharSequence'));
t('ele {List I,List J,CharSequence K,long L}', ele.includes('List I') && ele.includes('List J') && ele.includes('CharSequence K') && ele.includes('long L'));
const dle = R('dle.java');
t('dle implements Appendable', dle.includes('implements Appendable'));
t('dle {ele,f76,o7a,rnh}', dle.includes('ele I') && dle.includes('f76') && dle.includes('o7a') && dle.includes('rnh'));
const qoe = R('qoe.java');
t('qoe session {String,long,wx5}', qoe.includes('String') && qoe.includes('long j') && qoe.includes('wx5'));
t('qoe b(dle) consume', qoe.includes('b(dle'));
t('qoe e(ele,ele,rnh,bme)', qoe.includes('e(ele') && qoe.includes('bme'));
t('bme is enum', R('bme.java').includes('bme I') && R('bme.java').includes('bme J'));
t('ele CharSequence methods', ele.includes('length()') || ele.includes('charAt') || ele.includes('subSequence') || ele.includes('toString'));
t('dle append methods', dle.includes('append'));
console.log('text-edit replay: ' + n + '/10 checks green');
