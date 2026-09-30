// Phase 1353 — baseline attribution audit (correct mislabels)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('b90 = AbstractSet (mislabel)', readFileSync(D + 'b90.java', 'utf8').includes('AbstractSet'));
t('w4a = synthetic when-map (mislabel)', readFileSync(D + 'w4a.java', 'utf8').includes('synthetic'));
t('wy5 = ko3/draw modifier (mislabel)', readFileSync(D + 'wy5.java', 'utf8').includes('ko3'));
t('gn3 = node base (mislabel)', readFileSync(D + 'gn3.java', 'utf8').includes('n73'));
t('ms1 = float pair (correct)', readFileSync(D + 'ms1.java', 'utf8').includes('float'));
t('dr4 = hr4 smoother family (ok)', readFileSync(D + 'dr4.java', 'utf8').includes('hr4'));
t('g5d = ShapeDetectorOutput (real)', readFileSync(D + 'g5d.java', 'utf8').includes('ShapeDetectorOutput'));
t('uf8 = detector iface (real)', readFileSync(D + 'uf8.java', 'utf8').includes('xf8'));
t('f5d = point cluster (real)', readFileSync(D + 'f5d.java', 'utf8').includes('0.05'));
t('sqh = lm9 registry (partial)', readFileSync(D + 'sqh.java', 'utf8').includes('lm9'));
console.log('baseline-attribution replay: ' + n + '/10 checks green');
