// Phase 937 — utf Uuid 布局 + di7 迭代器偏移回归
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const utf = rd('utf.java');
ok(utf.includes('extends xwd'), 'utf = inline struct');
ok(utf.match(/long d\(\)[\s\S]{0,60}getLong\(this\.I\)/), 'bitsHigh @+0');
ok(utf.match(/long c\(\)[\s\S]{0,60}getLong\(this\.I \+ 8\)/), 'bitsLow @+8');
ok(utf.includes('Uuid(bitsLow='), 'utf = Uuid');

const di7 = rd('di7.java');
ok(di7.includes('implements hmf'), 'di7 = hmf iterator');
ok(di7.match(/wd8Var\.g\(22\)/) && di7.match(/wd8Var\.g\(24\)/) && di7.match(/wd8Var\.g\(20\)/),
  'di7(wd8) reads g(20/22/24)');
ok(di7.match(/dm2Var\.g\(26\)/) && di7.match(/dm2Var\.g\(24\)/), 'di7(dm2) reads g(24/26)');
ok(di7.match(/gdVar\.g\(8\)/) && di7.match(/gdVar\.g\(6\)/), 'di7(gd) reads g(6/8)');
ok(rd('ei7.java').includes('dm2Var.g(22)'), 'ei7(dm2) reads g(22)');
ok(di7.includes('ByteBuffer byteBufferG') && di7.includes('byteBufferG.position()'),
  'di7 = zero-copy slice iterator');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
