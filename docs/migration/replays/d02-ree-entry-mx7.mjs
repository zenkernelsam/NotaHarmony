// Phase 961 — ree 总入口 + rgc fail-loud + pce lazy + mx7 MapBuilder
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const ree = readFileSync(`${ROOT}/ree.java`, 'utf8');
const rgc = readFileSync(`${ROOT}/rgc.java`, 'utf8');
const pce = readFileSync(`${ROOT}/pce.java`, 'utf8');
const mx7 = readFileSync(`${ROOT}/mx7.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// ree = master serialization entry
ok(/pce a = new pce\(new z0c\(24\)\)/.test(ree), 'ree.a = lazy z0c(24) registry');
ok(/static final int a\(cee ceeVar, a aVar\)/.test(ree), 'ree.a = dispatch (cee,builder)');
ok(/IdentityHashMap\) a\.getValue\(\)\)\.get\(ceeVar\.getClass\(\)\)/.test(ree), 'ree.a: IdentityHashMap.get(runtime class)');
ok(/wx4Var\.invoke\(ceeVar, aVar\)/.test(ree), 'ree.a: wx4.invoke(cee,builder) -> int');
ok(/rgc\.b\(mpb\.a\.b\(ceeVar\.getClass\(\)\)/.test(ree), 'ree.a: unknown -> rgc.b(KClass name)');
ok(/static final byte\[\] b\(cee ceeVar\)/.test(ree) && /aVarA\.p\(a\(ceeVar, aVarA\)\)/.test(ree), 'ree.b = serialize-to-bytes');
ok(/dk4\.a\(c8dVar\)/.test(ree) && /rh8\.q\(c8dVar/.test(ree), 'ree.b: pooled builder + closeFinally');

// rgc.b = fail-loud guard
ok(/IllegalStateException\(\("Unknown type '"/.test(rgc), 'rgc.b throws IllegalStateException');
ok(/will lead to data loss when written to disk\. Likely programmer error\./.test(rgc), 'rgc.b message = data-loss guard');

// pce = SynchronizedLazyImpl
ok(/volatile Object J;/.test(pce) && /this\.J = t3i\.c0/.test(pce), 'pce: volatile J = UNINITIALIZED sentinel');
ok(/synchronized \(this\.K\)/.test(pce) && /this\.I = null/.test(pce), 'pce: DCL + I=null after init');
ok(/implements cx6, Serializable/.test(pce), 'pce = Kotlin Lazy impl');

// mx7 = Kotlin MapBuilder
ok(/class mx7 implements Map, Serializable, lk6/.test(mx7), 'mx7 = MapBuilder (lk6 marker)');
ok(/Object\[\] I;[\s\S]{0,100}Object\[\] J;[\s\S]{0,100}int\[\] K;[\s\S]{0,100}int\[\] L;/.test(mx7), 'mx7 = Object[] keys/vals + int[] buckets/chains');
ok(/highestOneBit\(\(i < 1 \? 1 : i\) \* 3\)/.test(mx7), 'mx7: bucket len = highestOneBit(cap*3)');
ok(/mx7Var\.U = true;[\s\S]{0,30}V = mx7Var/.test(mx7), 'mx7.V = sealed empty singleton');

console.log(`\nree-entry-mx7 replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
