// Phase 1018 — nr1 dependency roster
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const ssf = readFileSync(D + 'ssf.java', 'utf8');
const qr1 = readFileSync(D + 'qr1.java', 'utf8');
const jl3 = readFileSync(D + 'jl3.java', 'utf8');
const sxa = readFileSync(D + 'sxa.java', 'utf8');
const v2f = readFileSync(D + 'v2f.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ssf: 4-dep service', /public final q75 a;/.test(ssf) && /public final xrf b;/.test(ssf) && /public final vs4 c;/.test(ssf) && /public final pce d;/.test(ssf));
t('qr1: dual lazy pce', /public final pce a;/.test(qr1) && /public final pce b;/.test(qr1));
t('qr1: File getters', qr1.includes('public final File a()') && qr1.includes('public final File b()'));
t('qr1: lazy getValue', qr1.includes('this.a.getValue()'));
t('jl3: Flow+hl3', /public final sfb c;/.test(jl3) && jl3.includes('public final hl3 b('));
t('jl3: cx6 dep', jl3.includes('public jl3(cx6 cx6Var)'));
t('sxa: Context-only', /public final Context a;/.test(sxa));
t('v2f: t2f clock', v2f.includes('t2f') && /interface v2f|class v2f/.test(v2f));
t('ssf fields distinct', (ssf.match(/public final \w+ [a-z];/g) || []).length >= 4);
const nr1 = readFileSync(D + 'nr1.java', 'utf8');
t('nr1 ctor takes all', nr1.includes('ssf') && nr1.includes('qr1') && nr1.includes('jl3') && nr1.includes('sxa'));
console.log('nr1-deps replay: ' + n + '/10 checks green');
