// Phase 1093 — hvd FB-vector→readonly-List + m2/y3 base
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const hvd = R('hvd'), m2 = R('m2'), y3 = R('y3'), g2c = R('g2c');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('hvd implements List,ik6', hvd.includes('implements List, ik6'));
t('hvd: {cee I payload, cxc J}', hvd.includes('cee I') && hvd.includes('cxc J'));
t('hvd ctor takes cee payload', hvd.includes('hvd(cee ceeVar)'));
t('hvd: read-only (add throws)', hvd.includes('UnsupportedOperationException("Operation is not supported for read-only collection")'));
t('g2c extends hvd wraps f2c', g2c.includes('extends hvd'));
t('m2 implements Collection,ik6', m2.includes('implements Collection, ik6'));
t('m2: read-only base (add/All throw)', (m2.match(/UnsupportedOperationException/g) || []).length >= 2);
t('y3 extends m2', y3.includes('extends m2'));
t('gxc extends y3 (wire anchor list)', R('gxc').includes('extends y3'));
t('hvd: ik6 immutable marker', hvd.includes('ik6'));
console.log('fb-list replay: ' + n + '/10 checks green');
