// Phase 894 — ka4 校验契约 + ddg 校验链回归
// 证据：docs/migration/evidence/phase-894-ka4-validation-chain.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const ka4 = rd('ka4.java');
const ln2 = rd('ln2.java');
const wa0 = rd('wa0.java');
const sw9 = rd('sw9.java');
const ddg = rd('ddg.java');

// ---- ka4 契约 ----
ok(ka4.includes('public interface ka4') && ka4.includes('String a()'),
  'ka4 = String a() interface');
ok(sw9.includes('implements ka4') && wa0.includes('implements ka4') &&
   ln2.includes('implements ka4'), 'payloads implement ka4');

// ---- ln2.a() ----
ok(ln2.includes('Cannot create 0 pages'), 'ln2 zero-page rule');
ok(ln2.includes('Number of pages created must match the number of consumed pages in the PDF'),
  'ln2 pageCount=pagesConsumed rule');
ok(ln2.includes('ddg.g(nz9Var') && ln2.includes('ddg.f(sw9VarL)'),
  'ln2 cascades ddg.g/ddg.f');

// ---- wa0.a() ----
ok(wa0.includes('Asset file size must be larger than 0'), 'wa0 fileSize>0');
ok(wa0.includes('Asset mime type must not be empty'), 'wa0 mime nonempty');
ok(wa0.includes('Asset file name must not be empty'), 'wa0 fileName nonempty');
ok(wa0.includes('Integer.compareUnsigned(l(), 0) <= 0'), 'wa0 unsigned size compare');

// ---- sw9.a() = ddg.f 委托 ----
ok(sw9.includes('return ddg.f(this)'), 'sw9.a delegates ddg.f');

// ---- ddg.f(sw9) ----
ok(ddg.includes('Page count must be greater than 0'), 'ddg.f totalPageCount>0');
ok(ddg.includes('Must consume more than 0 pages'), 'ddg.f pagesConsumed>0');
ok(ddg.includes('Must specify a crop box size for each page consumed'),
  'ddg.f cropBoxes=pagesConsumed');
ok(ddg.includes('Cannot consume pages beyond the total page count of the PDF'),
  'ddg.f offset+consumed<=total');
ok(ddg.includes('k(qedVar, "Crop box")'), 'ddg.f per-cropBox k() check');

// ---- ddg.g(nz9) ----
ok(ddg.includes('PDF pages require an explicitly specified size to prevent fallback to the default note size'),
  'ddg.g PDF requires explicit size');
ok(ddg.includes('Cannot create margins larger than the page size'),
  'ddg.g margins<=page rule');
ok(ddg.includes('Cannot rotate to non cardinal directions'), 'ddg.g cardinal rotation');
ok(ddg.includes('1.5707964') && ddg.includes('3.1415927') &&
   ddg.includes('4.712389'), 'ddg.g rotation set {pi/2,pi,3pi/2}');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
