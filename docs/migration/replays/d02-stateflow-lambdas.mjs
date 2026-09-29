// Phase 1036 — continuation/lambda primitives + asd StateFlow
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const ff2 = readFileSync(D + 'ff2.java', 'utf8');
const n8e = readFileSync(D + 'n8e.java', 'utf8');
const wx4 = readFileSync(D + 'wx4.java', 'utf8');
const asd = readFileSync(D + 'asd.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ff2: BaseContinuationImpl', ff2.includes('extends lr0') && ff2.includes('public ff2(ef2'));
t('n8e: SuspendLambda', n8e.includes('extends ff2 implements hy4'));
t('n8e: arity', n8e.includes('public int getArity()'));
t('wx4: FunctionN iface', wx4.includes('extends xx4'));
t('asd: MutableStateFlow', asd.includes('implements hl8, ml4, cz4'));
t('asd: _state$volatile ARFU', asd.includes('_state$volatile') && asd.includes('AtomicReferenceFieldUpdater'));
t('asd: int M seq', /public int M;/.test(asd));
t('asd: init value ctor', asd.includes('public asd(Object obj)'));
const o5 = readFileSync(D + 'o5.java', 'utf8');
t('o5: StateFlow impl base', /class o5|interface o5/.test(o5));
const hy4 = readFileSync(D + 'hy4.java', 'utf8');
t('hy4: arity iface', /interface hy4|class hy4/.test(hy4));
console.log('stateflow-lambdas replay: ' + n + '/10 checks green');
