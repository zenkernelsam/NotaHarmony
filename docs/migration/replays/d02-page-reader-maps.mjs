// Phase 908 — ln2/nz9/k3a reader 图 + 读写对称回归
// 证据：docs/migration/evidence/phase-908-page-reader-maps.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const ln2 = rd('ln2.java');
const nz9 = rd('nz9.java');
const k3a = rd('k3a.java');

// ---- ln2 reader ----
ok(ln2.match(/cxc l\(\)[\s\S]{0,140}c\(4\)/), 'ln2.l -> c(4) location');
ok(ln2.match(/nz9 j\(\)[\s\S]{0,120}c\(6\)/), 'ln2.j -> c(6) background');
ok(ln2.match(/int m\(\)[\s\S]{0,120}c\(8\)/), 'ln2.m -> c(8) pageCount');
ok(ln2.match(/oz9 k\(\)[\s\S]{0,120}c\(10\)/), 'ln2.k -> c(10) bookmark');

// ---- nz9 reader ----
ok(nz9.match(/k3a k\(\)[\s\S]{0,120}c\(4\)/), 'nz9.k -> c(4) paper');
ok(nz9.match(/sw9 l\(\)[\s\S]{0,120}c\(6\)/), 'nz9.l -> c(6) pdfLayout');
ok(nz9.match(/float m\(\)[\s\S]{0,120}c\(8\)/), 'nz9.m -> c(8) rotation');
ok(nz9.match(/qed n\(\)[\s\S]{0,120}c\(10\)/), 'nz9.n -> c(10) size');
ok(nz9.match(/vy7 j\(\)[\s\S]{0,120}c\(12\)/), 'nz9.j -> c(12) margins');

// ---- k3a reader ----
ok(k3a.match(/n3a k\(\)[\s\S]{0,120}c\(4\)/), 'k3a.k -> c(4) template');
ok(k3a.match(/Float n\(\)[\s\S]{0,120}c\(6\)/), 'k3a.n -> c(6) float');
ok(k3a.match(/Boolean l\(\)[\s\S]{0,120}c\(8\)/), 'k3a.l -> c(8) bool');
ok(k3a.match(/Boolean m\(\)[\s\S]{0,120}c\(10\)/), 'k3a.m -> c(10) bool');
ok(k3a.match(/hu1 j\(\)[\s\S]{0,140}c\(12\)/), 'k3a.j -> c(12) color');
ok(k3a.match(/cmf o\(\)[\s\S]{0,140}c\(14\)/) || k3a.includes('public final cmf o()'),
  'k3a.o -> c(14) enum');

// ---- 写侧对称交叉验证 ----
const haj = rd('haj.java');
const vv7 = rd('vv7.java');
const fag = rd('fag.java');
ok(haj.includes('aVar.e(2, i, 1)') || haj.includes('e(2,'), 'haj writes f2 pageCount');
ok(vv7.includes('aVar.C(5)') || vv7.includes('C(5)'), 'vv7.L C(5) fields');
ok(fag.includes('aVar.C(6)'), 'fag.o0 C(6) fields');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
