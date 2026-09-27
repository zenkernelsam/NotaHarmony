// Phase 945 — 写端↔读端对称首证回归
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const haj = rd('haj.java');
ok(haj.includes('int c(ln2 ln2Var, a aVar)'), 'haj.c = ln2 writer');
ok(haj.match(/aVar\.C\(4\)/), 'ln2 writer = 4-slot table');
ok(haj.match(/aVar\.j\(0, nti\.X\(/), 'f0 = nti.X inline cxc');
ok(haj.match(/aVar\.h\(1, numValueOf/), 'f1 = nz9 offset (vv7.L)');
ok(haj.match(/aVar\.e\(2, iM, 1\)/), 'f2 = pageCount default 1');
ok(haj.match(/aVar\.c\(3, oz9VarK\.I, 0\)/), 'f3 = bookmarked default 0');

const nti = rd('nti.java');
ok(nti.includes('int X(cxc cxcVar, a aVar)'), 'nti.X = cxc inline writer');
ok(nti.match(/aVar\.t\(4, 12\)[\s\S]{0,200}aVar\.w\(iC\)[\s\S]{0,60}aVar\.w\(iD\)[\s\S]{0,60}aVar\.s\(2\)[\s\S]{0,60}aVar\.y\(sC\)/),
  'nti.X writes {site,pad,ts,idx} backwards = {u16@0,pad@2,u32@4,u32@8}');

// read-side cross-check (Phase 880/908 already pinned)
const ln2 = rd('ln2.java');
ok(ln2.match(/c\(4\)/) && ln2.match(/c\(6\)/) && ln2.match(/c\(8\)/) && ln2.match(/c\(10\)/),
  'reader c(4..10) mirrors writer f0-f3');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
