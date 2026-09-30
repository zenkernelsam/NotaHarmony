// Phase 1131 — e4c.g insert algorithm + public API surface
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const e4c = R('e4c'), njj = R('njj'), d4c = R('d4c');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('e4c.g(mr5,exc,m3c,bool)→d4c', e4c.includes('d4c g(mr5 mr5Var, exc excVar, m3c m3cVar, boolean z)'));
t('g: njj.t tree-walk', e4c.includes('njj.t(iwcVar'));
t('g: knb/mnb out-params', e4c.includes('knbVar.I') && e4c.includes('mnbVar.I'));
t('g: s3c split offset', e4c.includes('knbVar.I = numY.intValue()') || e4c.includes('.e + knb'));
t('g: n4c.a codepoint→idx', e4c.includes('n4c.a(s3cVar'));
t('g: charSeq.subSequence split', e4c.includes('charSequenceSubSequence'));
t('g: tombstone skip njj.L+zm7', e4c.includes('njj.L(iwcVar') && e4c.includes('zm7'));
t('g: negative-split log + k4c.e=true', e4c.includes('split offset negative') || e4c.includes('k4cVar2.e = true'));
t('o(exc)→pos / w(int)→exc / y(cxc)→pos', e4c.includes('Integer o(exc excVar)') && e4c.includes('exc w(int i)') && e4c.includes('Integer y(cxc'));
t('d4c marker iface + getText jxc', d4c.includes('interface d4c') && e4c.includes('jxc getText()'));
console.log('insert replay: ' + n + '/10 checks green');
