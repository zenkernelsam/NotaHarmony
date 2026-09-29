// Phase 1073 — entity iface hierarchy be5→qsa→xy3→categories
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const qsa = R('qsa'), xy3 = R('xy3'), o06 = R('o06'), k5d = R('k5d'), wy0 = R('wy0'), fkb = R('fkb'), v69 = R('v69');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('qsa extends be5 + d(uq9,ie8) apply', qsa.includes('extends be5') && qsa.includes('void d(uq9 uq9Var, ie8 ie8Var)'));
t('xy3: build()→yy3 snapshot', xy3.includes('yy3 build()'));
t('o06 extends xy3,qsa', o06.includes('extends xy3, qsa'));
t('k5d extends xy3,qsa', k5d.includes('extends xy3, qsa'));
t('wy0 extends xy3,qsa', wy0.includes('extends xy3, qsa'));
t('fkb implements yjb,xy3', fkb.includes('implements yjb, xy3'));
t('fkb.build()→yy3', fkb.includes('yy3 build()'));
t('v69 t()→o06 map', v69.includes('(o06) v69Var.t().get(qo5VarN)') || v69.includes('o06Var = (o06) v69Var.t()'));
t('v69 u()→k5d + s()→wy0 maps', v69.includes('(k5d) v69Var.u()') && v69.includes('(wy0) v69Var.s()'));
t('wy0 subtype xhe', v69.includes('wy0Var instanceof xhe'));
console.log('entity-hierarchy replay: ' + n + '/10 checks green');
