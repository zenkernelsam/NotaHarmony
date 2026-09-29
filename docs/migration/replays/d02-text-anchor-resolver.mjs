// Phase 994 — z5c.y text-anchor->rect resolver + u3c
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const z5c = readFileSync(`${ROOT}/z5c.java`, 'utf8');
const u3c = readFileSync(`${ROOT}/u3c.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

const yBody = z5c.slice(z5c.indexOf('final u3c y('), z5c.indexOf('void z(long[]'));

// signature + null branch
ok(/public static final u3c y\(qo5 qo5Var, x09 x09Var\)/.test(z5c), 'z5c.y signature (qo5, x09)->u3c');
ok(/if \(qo5Var == null\)/.test(yBody), 'z5c.y: null-id -> page-level branch');
ok(/a79Var\.c\(\) == tv6\.PAGELESS/.test(yBody), 'z5c.y: PAGELESS mode special-case');
ok(/nz9Var\.j\(\)/.test(yBody) && /nz9Var\.n\(\)/.test(yBody), 'z5c.y: nz9 margins+size reads');
ok(/qedVarN = m09\.b/.test(yBody), 'z5c.y: null size -> m09.b default');

// entity branch
ok(/a79Var2\.E\.I\.get\(qo5Var\)/.test(yBody) && /a79Var2\.I\.get\(qo5Var\)/.test(yBody), 'z5c.y: dual entity-map lookup E.I + I');
ok(/Text block with id not found/.test(yBody) && /yn7\.TEXT/.test(yBody), 'z5c.y: missing entity -> TEXT log + null');
ok(/cie cieVar = \(cie\) xheVar/.test(yBody), 'z5c.y: xhe -> cie cast');
ok(/vy7 vy7Var = cieVar\.f;[\s\S]{0,60}ry0 ry0Var = cieVar\.b/.test(yBody), 'z5c.y: cie.f=margins, cie.b=layout');
ok(/if \(di3Var\.compareTo\(di3Var2\) < 0\)/.test(yBody), 'z5c.y: height >=1.0f clamp');
ok(/do6\.i\(ry0Var\.o, a79Var2\.h\)/.test(yBody), 'z5c.y: page lookup do6.i for origin');

// u3c shape
ok(/class u3c|public.*u3c\(/.test(u3c), 'u3c rect class');

console.log(`\ntext-anchor-resolver replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
