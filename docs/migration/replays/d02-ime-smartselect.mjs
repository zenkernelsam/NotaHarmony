// Phase 1256 — eje/yla/k6f IME + smart-select
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const eje = R('eje.java');
t('eje n73 q52+qie', eje.includes('extends n73 implements q52, qie'));
t('eje k6f Y session', eje.includes('k6f Y'));
t('eje tqd c0 job', eje.includes('tqd c0'));
t('eje cmb e0 geometry', eje.includes('cmb e0'));
t('eje m/q(mv6) position', eje.includes('m(mv6 mv6Var)') && eje.includes('q(mv6'));
const yla = R('yla.java');
t('yla TextClassifier f', yla.includes('TextClassifier f'));
t('yla classifyText Request', yla.includes('classifyText') && yla.includes('TextClassification.Request.Builder'));
t('yla jqe.g/f range', yla.includes('jqe.g') && yla.includes('jqe.f'));
const k6f = R('k6f.java');
t('k6f eje a + h6f b session', k6f.includes('eje a') && k6f.includes('h6f b'));
const qie = R('qie.java');
t('qie keyboard iface', qie.includes('interface qie'));
console.log('ime-smartselect replay: ' + n + '/10 checks green');
