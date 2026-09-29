// Phase 990 — lgf op-tree + mia DFS iterator + k79 sort keys + ldj.G1 chain
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const lgf = readFileSync(`${ROOT}/lgf.java`, 'utf8');
const mia = readFileSync(`${ROOT}/mia.java`, 'utf8');
const rgf = readFileSync(`${ROOT}/rgf.java`, 'utf8');
const k79 = readFileSync(`${ROOT}/k79.java`, 'utf8');
const ldj = readFileSync(`${ROOT}/ldj.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// lgf = persistent op-tree node
ok(/public static final lgf d = new lgf\(0, new Object\[0\], null\)/.test(lgf), 'lgf.d = EMPTY singleton');
ok(/public int a;\s*public Object\[\] b;\s*public final f16 c/.test(lgf), 'lgf: {size, node[], f16}');
ok(/obj instanceof lgf \? \(\(lgf\) obj\)\.a\(\) : 1/.test(lgf), 'lgf.a(): recursive size');
ok(/public static lgf f\(int i, Object obj, int i2, Object obj2, int i3, f16 f16Var\)/.test(lgf), 'lgf.f = node factory');
ok(/public final boolean b\(int i, int i2, Object obj\)/.test(lgf) && /public final boolean c\(lgf lgfVar, int i\)/.test(lgf), 'lgf: immutable set/append');

// mia = DFS iterator over rgf frames
ok(/class mia implements Iterator, ik6/.test(mia), 'mia: Iterator impl');
ok(/ArrayList arrayListO0 = m18\.o0\(new rgf\(\)\)/.test(mia), 'mia: rgf frame stack');
ok(/this\.K = true/.test(mia), 'mia: K = hasMore flag');
ok(/rgfVar\.a = objArr;\s*rgfVar\.b = 0/.test(mia), 'mia: frame init node[]+idx0');
ok(/this\.K = false/.test(mia), 'mia: exhaustion -> K=false');

// rgf = iteration frame {node[], idx}
ok(/class rgf|public.*rgf\(/.test(rgf), 'rgf frame class');

// k79 cases 3/4 = op sort keys
ok(/case 3:[\s\S]{0,120}new mmf\(uq9Var\.l\(\)\.d\(\)\)/.test(k79), 'k79(3): mmf(id.timestamp) primary');
ok(/case 4:[\s\S]{0,140}new ymf\(uq9Var2\.l\(\)\.c\(\)\)/.test(k79), 'k79(4): ymf(id.site) secondary');

// ldj.G1 = chained comparator
ok(/public static d02 G1\(ix4\.\.\. ix4VarArr\)/.test(ldj) && /return new d02\(ix4VarArr, 0\)/.test(ldj), 'ldj.G1 -> d02 chain');
ok(/Failed requirement/.test(ldj), 'ldj.G1: empty-args throw');

console.log(`\nop-tree replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
