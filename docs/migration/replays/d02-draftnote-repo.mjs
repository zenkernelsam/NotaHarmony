// Phase 1021 — hl3 DraftNote DAO + vs4 logger + jl3 correction
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const hl3 = readFileSync(D + 'hl3.java', 'utf8');
const jl3 = readFileSync(D + 'jl3.java', 'utf8');
const vs4 = readFileSync(D + 'vs4.java', 'utf8');
const q75 = readFileSync(D + 'q75.java', 'utf8');
const cx6 = readFileSync(D + 'cx6.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('hl3: x5c+wp1+sh8 Room DAO', /public final x5c a;/.test(hl3) && /new wp1\(this, 3\)/.test(hl3) && /new sh8\(22\)/.test(hl3));
t('hl3: DraftNote delete', hl3.includes('DELETE FROM DraftNote WHERE noteId IN'));
t('hl3: batched Collection', hl3.includes('public final Object a(Collection collection, ff2 ff2Var)'));
t('jl3: exposes hl3 (DraftNote repo)', jl3.includes('public final hl3 b('));
t('jl3: cx6 dep', jl3.includes('public jl3(cx6 cx6Var)'));
t('vs4: v7d+sfb', /public final v7d a;/.test(vs4) && /public final sfb b;/.test(vs4));
t('vs4.a: LOGIN telemetry', vs4.includes('yn7.LOGIN') && vs4.includes('xn7'));
t('q75: 3-dep service', q75.includes('public q75(cx6 cx6Var, vs4 vs4Var, dt4 dt4Var)'));
t('cx6: iface', /public interface cx6/.test(cx6) && cx6.includes('boolean a('));
const nr1 = readFileSync(D + 'nr1.java', 'utf8');
t('nr1 jl3 field (DraftNote repo)', /public final jl3 e;/.test(nr1));
console.log('draftnote-repo replay: ' + n + '/10 checks green');
