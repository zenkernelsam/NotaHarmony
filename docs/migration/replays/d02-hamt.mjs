// Phase 1114 — lgf HAMT + f16 token + collection bases
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const lgf = R('lgf'), f16 = R('f16'), m2 = R('m2'), n5 = R('n5'),
      zr5 = R('zr5'), hw3 = R('hw3');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('lgf {int,Object[],f16} trie node', lgf.includes('int ') && lgf.includes('Object[] b') && lgf.includes('f16'));
t('lgf empty node sentinel', lgf.includes('new lgf(0, new Object[0], null)'));
t('lgf.f 2-level assoc', lgf.includes('lgf f(int i, Object obj, int i2, Object obj2, int i3, f16'));
t('f16 mega-merge token', f16.includes('implements') && f16.includes('new f16(1'));
t('m2 read-only base (add throws)', m2.includes('implements Collection, ik6') && m2.includes('add('));
t('n5 extends m2 Set', n5.includes('extends m2 implements Set'));
t('zr5 persistent list marker', zr5.includes('extends List, Collection, ik6'));
t('hw3 empty list singleton', hw3.includes('hw3 I = new hw3()'));
t('hw3 Serializable+RandomAccess', hw3.includes('Serializable') && hw3.includes('RandomAccess'));
t('k5c uses hw3.I', R('k5c').includes('hw3.I'));
console.log('hamt replay: ' + n + '/10 checks green');
