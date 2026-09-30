// Phase 1138 — v69.c three-phase suspend dispatch
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const v69 = R('v69');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('x82.F parallel awaitAll', v69.includes('x82.F(hk4VarV0, iAvailableProcessors'));
t('dh3.a Dispatchers', v69.includes('dh3.a'));
t('q69 parallel lambda', v69.includes('q69Var'));
t('th7 persistent-set builder', v69.includes('th7 th7VarS = m18.S()'));
t('union all entity keySets', v69.includes('th7VarS.addAll(l().keySet())') && v69.includes('th7VarS.addAll(k().keySet())'));
t('g(union,dedupe)→e0a plan', v69.includes('e0a e0aVarG = g(m18.E(th7VarS), linkedHashMap)'));
t('yc6.z apply plan', v69.includes('yc6VarQ.z(e0aVarG, !yc6VarQ.H(), al2VarJ2, list)'));
t('yc6.G label-2 commit', v69.includes('yc6VarQ2.G((List) obj, al2VarJ3, list2, s69Var)'));
t('label reset UNDEFINED_DURATION', v69.includes('RecyclerView.UNDEFINED_DURATION'));
t('resume-before-invoke guard', v69.includes("call to 'resume' before 'invoke'"));
console.log('v69-dispatch replay: ' + n + '/10 checks green');
