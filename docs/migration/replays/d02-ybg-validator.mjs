// Phase 948 — ybg 校验驱动回归
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const ybg = readFileSync(join(SRC, 'ybg.java'), 'utf8');

ok(ybg.match(/void c\(ka4 ka4Var\)/) && ybg.match(/strA == null[\s\S]{0,60}d\(strA\)/),
  'ybg.c = a()->null-passes/d(err) driver');
ok(ybg.match(/void d\(String str\)[\s\S]{0,120}yn7\.MODEL[\s\S]{0,80}ValidationException/),
  'ybg.d = yn7.MODEL log + throw');
ok(ybg.includes('ValidationException'), 'ValidationException type');

// factories calling ybg.c
const ys2 = readFileSync(join(SRC, 'ys2.java'), 'utf8');
ok(ys2.includes('ybg.c(dm2Var)'), 'ys2.d calls ybg.c post-build');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
