// Phase 976 — hu1 Color 4B RGBA + z5c.P 写器 + ao2 required
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const hu1 = readFileSync(`${ROOT}/hu1.java`, 'utf8');
const z5c = readFileSync(`${ROOT}/z5c.java`, 'utf8');
const ao2 = readFileSync(`${ROOT}/ao2.java`, 'utf8');
const x4d = readFileSync(`${ROOT}/x4d.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// hu1 = 4B inline struct Color{bitsR,G,B,A}
ok(/class hu1 extends xwd/.test(hu1), 'hu1 extends xwd (inline struct)');
ok(/Color\(bitsR=/.test(hu1) && /bitsA=/.test(hu1), 'hu1 = Color{bitsR,G,B,A}');
ok(/cmf\.a\(f\(\)\)/.test(hu1) && /cmf\.a\(c\(\)\)/.test(hu1), 'hu1: components via cmf UByte');

// z5c.P = hu1 writer: t(1,4) + 4 bytes pushed A,B,G,R
const pm = z5c.match(/static final int P\(hu1 hu1Var, a aVar\)[\s\S]{0,400}/);
ok(!!pm, 'z5c.P = hu1 writer');
ok(/aVar\.t\(1, 4\)/.test(pm[0]), 'z5c.P: t(1,4) = 4B align1');
ok(/aVar\.u\(bC\);[\s\S]{0,30}aVar\.u\(bD\);[\s\S]{0,30}aVar\.u\(bE\);[\s\S]{0,30}aVar\.u\(bF\);/.test(pm[0]), 'z5c.P: u(A)+u(B)+u(G)+u(R) push order -> RGBA wire');

// ao2 required-slot mapping: f0 page cxc, f1 origin fqa, f9 color hu1
ok(/public final cxc r\(\)[\s\S]{0,60}c\(4\)/.test(ao2), 'ao2 r(): page cxc @f0');
ok(/public final fqa q\(\)[\s\S]{0,60}c\(6\)/.test(ao2), 'ao2 q(): origin fqa @f1');
ok(/public final hu1 k\(\)[\s\S]{0,60}c\(22\)/.test(ao2), 'ao2 k(): color hu1 @f9');
ok(/No value for \(required\) field color/.test(ao2), 'ao2: color required msg');
ok(/No value for \(required\) field page/.test(ao2) && /No value for \(required\) field origin/.test(ao2), 'ao2: page+origin required msgs');
ok(/Cannot create shapes with variable width ink/.test(ao2), 'ao2: varwidth-ink guard');
ok(/ink_effects require a Pen or Highlighter tool/.test(ao2), 'ao2: ink-effects tool guard');

// x4d is a synthetic lambda class, not a wire enum
ok(/final \/\* synthetic \*\/ class x4d/.test(x4d), 'x4d = synthetic lambda class');

console.log(`\nhu1-color replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
