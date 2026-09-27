// Phase 891 — mmf=UInt 值类 + xw9 枚举回归
// 证据：docs/migration/evidence/phase-891-mmf-uint-xw9.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const mmf = rd('mmf.java');
const xw9 = rd('xw9.java');
const sw9 = rd('sw9.java');
const wa0 = rd('wa0.java');
const ln2 = rd('ln2.java');

// ---- mmf = UInt ----
ok(mmf.includes('public final class mmf implements Comparable'), 'mmf Comparable');
ok(mmf.includes('public final int I'), 'mmf raw int field');
ok(mmf.includes('& 4294967295L'), 'mmf.a unsigned format');
ok(mmf.includes('this.I ^ RecyclerView.UNDEFINED_DURATION') ||
   mmf.includes('^ RecyclerView.UNDEFINED_DURATION'), 'mmf unsigned compare trick');
ok(mmf.includes('public final String toString()'), 'mmf toString');

// ---- mmf 使用点 = UInt32 语义 ----
ok(sw9.includes('mmf.a(p())') && sw9.includes('mmf.a(o())') &&
   sw9.includes('mmf.a(n())'), 'sw9 page counts mmf x3');
ok(wa0.includes('mmf.a(l())'), 'wa0 fileSize mmf');
ok(ln2.includes('mmf.a'), 'ln2 pageCount mmf');

// ---- xw9 枚举 ----
ok(xw9.includes('public final class xw9'), 'xw9 enum class');
ok(xw9.includes('DOWNSCALING_AND_MAX_BOX((byte) 0)') ||
   xw9.includes('DOWNSCALING_AND_MAX_BOX'), 'xw9 DOWNSCALING_AND_MAX_BOX');
ok(xw9.includes('DOWNSCALING_AND_CROP_BOX'), 'xw9 DOWNSCALING_AND_CROP_BOX');
ok(xw9.includes('FIT_AND_CROP_BOX((byte) 2)') ||
   xw9.includes('FIT_AND_CROP_BOX'), 'xw9 FIT_AND_CROP_BOX=2');
ok(xw9.includes('public final byte I'), 'xw9 byte value field');

const j7j = rd('j7j.java');
ok(j7j.includes('aVar.c(1, b, 2)'), 'j7j.c default = FIT_AND_CROP_BOX(2)');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
