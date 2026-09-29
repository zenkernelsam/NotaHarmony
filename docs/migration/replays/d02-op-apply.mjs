// Phase 1072 — v69 op-apply state machine + entity-map chain
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const v69 = R('v69'), fsi = R('fsi');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('v69: ordinal dispatch switch', v69.includes('uq9Var.m().ordinal()'));
t('v69: op appended to lia causal set', v69.includes('liaVar.add(uq9Var)'));
t('MODIFY_POSITIONS case 24: je8 payload', v69.includes('(je8) z5c.x(uq9Var5)'));
t('fsi.P: positionLocked flag', v69.includes('fsi.P(uq9Var5)'));
t('entity-ref loop: lv2.S(je8)→ie8', v69.includes('lv2.S(je8Var)') && v69.includes('ie8Var.n()'));
t('entity-map chain t()/u()/s()', v69.includes('v69Var.t().get(qo5VarN)') && v69.includes('v69Var.u().get(qo5VarN)') && v69.includes('v69Var.s().get(qo5VarN)'));
t('entity ifaces: o06/k5d/wy0 .d(op,ref)', v69.includes('o06Var.d(uq9Var5, ie8Var)') && v69.includes('k5dVar.d(uq9Var5, ie8Var)') && v69.includes('wy0Var.d(uq9Var5, ie8Var)'));
t('xhe special-case → t09 set', v69.includes('wy0Var instanceof xhe') && v69.includes('new t09(qo5VarN)'));
t('n()/k() fallback entity maps', v69.includes('v69Var.n().get(qo5VarN)') && v69.includes('v69Var.k().get(qo5VarN)'));
t('Inconsistent-logic telemetry error', v69.includes('Inconsistent logic internal to note'));
console.log('op-apply replay: ' + n + '/10 checks green');
