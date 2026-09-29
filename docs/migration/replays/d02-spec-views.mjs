// Phase 1113 — bxc spec view types: k5c/z4/kia/cl2
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const k5c = R('k5c'), z4 = R('z4'), kia = R('kia'), cl2 = R('cl2'), bxc = R('bxc');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('k5c {List,int[],int}', k5c.includes('List I') && k5c.includes('int[] J'));
t('k5c extends y3', k5c.includes('extends y3'));
t('k5c empty sentinel hw3.I+int[0]', k5c.includes('new k5c(hw3.I, new int[0])'));
t('cl2 Map,ik6 over hja', cl2.includes('implements Map, ik6') && cl2.includes('hja I'));
t('cl2 3×pce lazies', cl2.includes('pce J') && cl2.includes('pce K') && cl2.includes('pce L'));
t('cl2 zk2 Function0 lazy', cl2.includes('zk2'));
t('kia {lgf,int} extends n5', kia.includes('extends n5') && kia.includes('lgf I') && kia.includes('int J'));
t('kia empty sentinel lgf.d', kia.includes('new kia(lgf.d, 0)'));
t('z4 extends y3 implements zr5', z4.includes('extends y3 implements zr5'));
t('bxc uses all view types', bxc.includes('k5c b') && bxc.includes('z4 d') && bxc.includes('kia e') && bxc.includes('cl2 f'));
console.log('spec-views replay: ' + n + '/10 checks green');
