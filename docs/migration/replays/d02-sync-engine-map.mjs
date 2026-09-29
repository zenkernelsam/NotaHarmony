// Phase 1017 — nr1 sync-engine method map
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const nr1 = readFileSync(D + 'nr1.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('nr1: 9 deps', /public final oq1 a;/.test(nr1) && /public final nce b;/.test(nr1) && /public final v2f g;/.test(nr1));
t('nr1: dual Mutex+map', /public final em8 m;/.test(nr1) && /public final LinkedHashMap n;/.test(nr1) && /public final em8 o;/.test(nr1));
t('nr1: 3 sfb flows', /public final sfb j;/.test(nr1) && /public final sfb k;/.test(nr1) && /public final sfb l;/.test(nr1));
t('d(): kq1 DAO', nr1.includes('public final kq1 d()'));
t('e(): NoteBundleMetadataDatabase', nr1.includes('public final NoteBundleMetadataDatabase e()'));
t('b(): upload entry', nr1.includes('public final Object b(ttf ttfVar, ArrayList arrayList, ff2 ff2Var)'));
t('g(): Room jq1 query', nr1.includes('new jq1(kq1VarD, ttfVar, null, 1)') && nr1.includes('l96.J0('));
t('f(): dr1 coroutine', nr1.includes('dr1 dr1Var') && nr1.includes('public final Object f(ff2 ff2Var)'));
t('i+j: mega coroutines (decompile-skipped)', nr1.includes('nr1.i(ff2):java.lang.Object') && nr1.includes('nr1.j(ff2):java.lang.Object') && nr1.includes('instruction units count: 8622'));
// j is the biggest — the main state machine
const jStart = nr1.indexOf('public final java.lang.Object j(');
t('j: last/largest method', jStart > nr1.indexOf('public final java.lang.Object i('));
console.log('sync-engine-map replay: ' + n + '/10 checks green');
