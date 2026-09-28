// Phase 963 — z0c 三归并写器类拓扑：ywd(23)/pee(~31)/qee(11) = 65 表项
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const z0c = readFileSync(`${ROOT}/z0c.java`, 'utf8');
const qee = readFileSync(`${ROOT}/qee.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// 计数：80 put 总项（15 mx7 + 65 identityHashMap）
ok((z0c.match(/identityHashMap\.put\(/g) || []).length === 65, 'z0c: 65 table puts');
ok((z0c.match(/mx7Var\.put\(/g) || []).length === 15, 'z0c: 15 struct puts');

// 载体分布
ok((z0c.match(/new qee\(/g) || []).length === 11, 'z0c: 11 qee instances');
ok((z0c.match(/from class: ywd/g) || []).length >= 20, 'z0c: ywd anon writers');

// qee 序数→写器映射
const qeeMap = [
  ['k0j.c((ud8)', 'ud8 ModifyComment'],
  ['rr2.b((my3)', 'my3 EntityAnchor'],
  ['qdi.a((lhe)', 'lhe TextAnchor'],
  ['baj.c((rl2)', 'rl2 CreateBlock'],
  ['eaj.b((cm2)', 'cm2 CreateGroup'],
  ['haj.c((ln2)', 'ln2 CreatePage'],
  ['iuh.c((dp5)', 'dp5 ImageAsset'],
  ['fci.d((e46)', 'e46 InsertChar'],
  ['kci.j((f46)', 'f46 InsertString'],
];
for (const [fn, name] of qeeMap) {
  ok(qee.includes(`Integer.valueOf(${fn}`), `qee -> ${fn} = ${name}`);
}
ok(/ys2\.O\(aVar, cxcVarT/.test(qee), 'qee case5 -> ys2.O (CreateInk writer, dm2)');
ok(/class qee implements wx4/.test(qee) && /switch \(this\.I\)/.test(qee), 'qee = synthetic wx4 switch(this.I)');

// 关键 put 序数配对
ok(/identityHashMap\.put\(rl2\.class, new qee\(i9\)\)/.test(z0c), 'rl2 -> qee(3)');
ok(/identityHashMap\.put\(dm2\.class, new qee\(i7\)\)/.test(z0c), 'dm2 -> qee(5)');
ok(/identityHashMap\.put\(ln2\.class, new qee\(6\)\)/.test(z0c), 'ln2 -> qee(6)');
ok(/identityHashMap\.put\(ud8\.class, new qee\(0\)\)/.test(z0c), 'ud8 -> qee(0)');
ok(/identityHashMap\.put\(lhe\.class, new qee\(i13\)\)/.test(z0c), 'lhe -> qee(2)');
ok(/identityHashMap\.put\(qub\.class, new wx4\(\) \{ \/\/ from class: pee/.test(z0c), 'qub -> pee anon');

console.log(`\nz0c-three-classes replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
