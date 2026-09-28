// Phase 975 — 值类包装 mmf/tmf/cmf + jmf ByteList + ix4 provider
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const jmf = readFileSync(`${ROOT}/jmf.java`, 'utf8');
const mmf = readFileSync(`${ROOT}/mmf.java`, 'utf8');
const tmf = readFileSync(`${ROOT}/tmf.java`, 'utf8');
const cmf = readFileSync(`${ROOT}/cmf.java`, 'utf8');
const ix4 = readFileSync(`${ROOT}/ix4.java`, 'utf8');
const nl8 = readFileSync(`${ROOT}/nl8.java`, 'utf8');
const hd = readFileSync(`${ROOT}/hd.java`, 'utf8');
const xd8 = readFileSync(`${ROOT}/xd8.java`, 'utf8');
const ys2 = readFileSync(`${ROOT}/ys2.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// value-class wrappers: single primitive field + Comparable
ok(/class mmf implements Comparable/.test(mmf) && /public final int I;/.test(mmf), 'mmf = {int I} value class');
ok(/class tmf implements Comparable/.test(tmf) && /public final long I;/.test(tmf), 'tmf = {long I} value class (ZIndex)');
ok(/class cmf implements Comparable/.test(cmf) && /public final byte I;/.test(cmf), 'cmf = {byte I} UByte');

// jmf = ByteList interface
ok(/interface jmf/.test(jmf), 'jmf = interface');
ok(/int a\(\);/.test(jmf) && /byte h\(int i\);/.test(jmf), 'jmf: a()=size, h(i)=byteAt');
ok(/hmf iterator\(\);/.test(jmf), 'jmf: hmf byte iterator');

// implementations: nl8 mutable, hd/xd8 w71-frozen
ok(/class nl8 implements jmf/.test(nl8), 'nl8 = mutable jmf impl');
ok(/implements w71, jmf/.test(hd) && /implements w71, jmf/.test(xd8), 'hd/xd8 = w71+jmf (frozen variants)');

// ix4 = Function1 provider
ok(/interface ix4 extends xx4/.test(ix4) && /Object invoke\(Object obj\)/.test(ix4), 'ix4 = invoke() provider interface');

// ys2.O takes 3 jmf params (the ink path byte-vectors)
const sig = ys2.match(/static final int O\(a aVar,[^)]*\)/)[0];
ok((sig.match(/jmf jmfVar/g) || []).length === 3, 'ys2.O: three jmf params = ink path byte-vectors');
ok(/tmf tmfVar/.test(sig) && /mmf mmfVar/.test(sig), 'ys2.O: tmf (zIndex) + mmf params');

console.log(`\nvalue-wrappers replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
