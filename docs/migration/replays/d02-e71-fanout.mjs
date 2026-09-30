// Phase 1238 — e71 event-set fan-out
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const e71 = R('e71.java');
t('e71 implements ol4', e71.includes('implements ol4'));
t('e71 I case + J ekd', e71.includes('final /* synthetic */ int I') && e71.includes('final /* synthetic */ ekd J'));
t('e71 ctor(ekd,i)', e71.includes('e71(ekd ekdVar, int i)'));
t('e71 rj5 add', e71.includes('t76Var instanceof rj5') && e71.includes('ekdVar.add'));
t('e71 sj5 removes .a', e71.includes('t76Var instanceof sj5') && e71.includes('((sj5)'));
t('e71 zo4/ap4 pair', e71.includes('t76Var instanceof zo4') && e71.includes('((ap4)'));
t('e71 fwa timed add', e71.includes('t76Var instanceof fwa') && e71.includes('ekdVar.add(t76Var)'));
t('e71 gwa removes fwa.a', e71.includes('t76Var instanceof gwa') && e71.includes('((gwa)'));
t('e71 ewa end', e71.includes('t76Var instanceof ewa'));
t('e71 multi-case (>=2 switch)', (e71.match(/instanceof rj5/g)||[]).length >= 2);
console.log('e71-fanout replay: ' + n + '/10 checks green');
