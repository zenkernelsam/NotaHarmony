// Phase 1206 — vle.h semantics/autofill + j1 action dispatch
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const xvc = R('xvc.java');
t('xvc SemanticsPropertyReceiver g(wvc,Object)', xvc.includes('void g(wvc'));
const tvc = R('tvc.java');
t('tvc ContentDescription key', tvc.includes('"ContentDescription"'));
t('tvc TextEntryKey+Disabled+IsTraversalGroup', tvc.includes('"TextEntryKey"') && tvc.includes('"Disabled"') && tvc.includes('"IsTraversalGroup"'));
const vvc = R('vvc.java');
t('vvc editableText/textSelectionRange/imeAction props', vvc.includes('editableText') && vvc.includes('textSelectionRange') && vvc.includes('imeAction'));
t('vvc autofill fillableData', vvc.includes('fillableData'));
const vle = R('vle.java');
t('vle.h populates tvc.F/G/H/I', vle.includes('tvc.F') && vle.includes('tvc.G') && vle.includes('tvc.H') && vle.includes('tvc.I'));
t('vle.h AutofillValue.forText', vle.includes('AutofillValue.forText'));
t('vle.j1 dispatch 5/6/7', vle.includes('i == 6') && vle.includes('i == 5') && vle.includes('i != 7'));
t('vle.l1 flushes ll3->ml3', vle.includes('new ml3(ll3Var)'));
t('vle.k1 cancels tqd job', vle.includes('tqdVar.a(null)'));
console.log('vle-semantics replay: ' + n + '/10 checks green');
