// Phase 949 — z0c 全量写端注册表回归
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const z0c = readFileSync(join(SRC, 'z0c.java'), 'utf8');
const zwd = readFileSync(join(SRC, 'zwd.java'), 'utf8');

ok(zwd.match(/map\.get\(npbVar\.b\(cls\)\)[\s\S]{0,150}rgc\.b/), 'zwd.a = registry dispatch + fail-closed');
ok(zwd.includes('new pce(new z0c(21))'), 'z0c = lazy provider');

const STRUCTS = ['ua0','v01','hd1','hu1','xq3','qo5','vy7','fqa','ukb','bmb','cwb','cxc','qed','yyd','utf'];
for (const c of STRUCTS) {
  ok(z0c.includes(`mx7Var.put(npbVar.b(${c}.class)`), `struct serializer ${c}`);
}
const TABLES = ['ln2','ge8','yn2','ke8','e46','f46','pub','qub','f2c','me8','he8','io1','dm2','gd','wd8',
  'ao2','le8','cm2','vd8','rl2','td8','je8','s83','tdf','ee8','mqf','yda','tl2','ud8','ra0','l2d',
  'uf7','pra','oz8','lhe','my3','r29','uq9','vq9','vt9','zgb','sdf','nz9','k3a','sw9','wa0','akb','dp5',
  'z1d','z2d','k2d','y2d','g2d','m2d','n2d','o2d','j2d','a3d','p2d','lxc','p9','r60','yq3','q89'];
for (const c of TABLES) {
  ok(z0c.includes(`identityHashMap.put(${c}.class`), `table serializer ${c}`);
}
ok((z0c.match(/mx7Var\.put/g) || []).length === 15, '15 struct puts');
ok((z0c.match(/identityHashMap\.put/g) || []).length === 65, '65 table puts');
ok(!z0c.includes('b3d'), 'b3d SetWritingDirection has NO registered writer (embedded in he8)');
ok((z0c.match(/new qee\(/g) || []).length >= 10, 'qee enum dispatch writers');
ok((z0c.match(/from class: ywd/g) || []).length >= 25, 'ywd anonymous impls');
ok((z0c.match(/from class: pee/g) || []).length >= 25, 'pee anonymous impls');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
