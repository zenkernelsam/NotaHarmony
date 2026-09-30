// Phase 1122 — v69.b() note materialization + rvb/f1a/q07 snapshots
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const v69 = R('v69');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('v69(a79,boolean,ny3) ctor', v69.includes('v69(a79 a79Var, boolean z, ny3'));
t('v69.b()→a79 materialize', v69.includes('a79 b()'));
t('dirty check s==a79.g→reuse', v69.includes('a79Var.g') && v69.includes('return a79Var'));
t('iwc.c()→bxc live→spec', v69.includes('bxcVarC = ((iwc)') && v69.includes('.c()'));
t('al2.a()→cl2 tombstone→map', v69.includes('cl2VarA = ((al2)') && v69.includes('.a()'));
t('rvb(bxc,cl2,xgb) text-block snap', v69.includes('new rvb(bxcVarC, cl2VarA, xgbVar)'));
t('ria slot-fold wz9.build()', v69.includes('wz9') && v69.includes('.build()'));
t('bka.set + f()→z4 freeze', v69.includes('bkaVar.set') && v69.includes('bkaVar.f()'));
t('q07(z4) wrap', v69.includes('new q07(z4VarF)'));
t('f1a page snapshot ctor', v69.includes('new f1a('));
console.log('note-materialize replay: ' + n + '/10 checks green');
