// Phase 1208 — vle delegate architecture (bq4/ol3/u8e/xp4 sub-ViewModel tree)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const vle = R('vle.java');
t('vle ctor wires bq4+ol3+u8e', vle.includes('new bq4(') && vle.includes('new ol3(') && vle.includes('new u8e('));
t('vle ame 5-lambda dispatch', vle.includes('new ame(') && vle.includes('new ew('));
const bq4 = R('bq4.java');
t('bq4 sub-controller 4 ifaces', bq4.includes('extends n73') && bq4.includes('mvc') && bq4.includes('q52'));
const ol3 = R('ol3.java');
t('ol3 implements pl3,kv6', ol3.includes('pl3') && ol3.includes('kv6'));
t('ame implements pl3', R('ame.java').includes('implements pl3'));
const pl3 = R('pl3.java');
t('pl3 kl3 pointer callbacks', (pl3.match(/kl3 kl3Var/g)||[]).length>=4 && pl3.includes('P0(kl3'));
const u8e = R('u8e.java');
t('u8e bra+r93+ara', u8e.includes('bra') && u8e.includes('r93') && u8e.includes('ara'));
t('ql8 Object[] RandomAccess', R('ql8.java').includes('implements RandomAccess') && R('ql8.java').includes('Object[]'));
const xp4 = R('xp4.java');
t('xp4 modifier node iface dispatch', xp4.includes('extends od8') && xp4.includes('rd8') && xp4.includes('instanceof rd8'));
t('tqd extends s2 Job', R('tqd.java').includes('extends s2'));
console.log('vle-delegates replay: ' + n + '/10 checks green');
