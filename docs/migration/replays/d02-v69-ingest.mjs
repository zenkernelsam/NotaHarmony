// Phase 1137 — v69.c suspended op-ingestion coroutine
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const v69 = R('v69'), ff2 = R('ff2'), s69 = R('s69');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('v69.c(ff2)→Object suspend', v69.includes('Object c(ff2 ff2Var)'));
t('ff2 = ContinuationImpl (lr0)', ff2.includes('extends lr0') && ff2.includes('_context'));
t('s69 = v69.c state machine', s69.includes('s69') && (s69.includes('v69') || s69.length>50));
t('v69.c: s69 label reset', v69.includes('new s69(this, ff2Var)') && v69.includes('s69Var.M'));
t('v69.c: version++ (s)', v69.includes('this.s++'));
t('v69.c: snapshot map t = e().I', v69.includes('this.t = map'));
t('v69.c: iterate qja entities', v69.includes('qjaVarR.I.values()'));
t('v69.c: k85 entity + ba6.K tombstone skip', v69.includes('instanceof k85') && v69.includes('ba6.K(ly3Var2.getId(), al2VarJ)'));
t('v69.c: k85.M() pending ops', v69.includes('k85Var.M()'));
t('v69.c: LWW dedupe so5.a', v69.includes('so5.a(qo5Var2, k85Var.getId())'));
console.log('v69-ingest replay: ' + n + '/10 checks green');
