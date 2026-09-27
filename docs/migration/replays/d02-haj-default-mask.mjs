// Phase 877 — haj CreatePage 助手与 Kotlin $default 掩码语义回归
// 证据：docs/migration/evidence/phase-877-haj-default-mask.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const HARM = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/data';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

const haj = readFileSync(join(SRC, 'haj.java'), 'utf8');
const u5j = readFileSync(join(SRC, 'u5j.java'), 'utf8');
const ln2 = readFileSync(join(SRC, 'ln2.java'), 'utf8');

// ---- haj.a = Kotlin $default 存根 ----
ok(haj.includes('public static ln2 a(cxc cxcVar, nz9 nz9Var, int i, oz9 oz9Var, int i2)'),
  'haj.a stub signature');
ok(/\(i2 & 1\) != 0\) \{\s*cxcVar = null/.test(haj), 'mask bit0 -> cxc default null');
ok(/\(i2 & 2\) != 0\) \{\s*nz9Var = null/.test(haj), 'mask bit1 -> nz9 default null');
ok(/\(i2 & 8\) != 0\) \{\s*oz9Var = oz9\.UNBOOKMARKED/.test(haj), 'mask bit3 -> oz9 UNBOOKMARKED');
ok(!haj.includes('(i2 & 4)'), 'no &4 branch -> pageCount has no default in haj.a');

// ---- haj.a 建表字段 ----
ok(haj.includes('aVarA.C(4)'), 'ln2 built with C(4) fields');
ok(haj.includes('aVarA.j(0, nti.X(cxcVar, aVarA))'), 'field0 location = nti.X(cxc)');
ok(haj.includes('Integer.valueOf(vv7.L(nz9Var, aVarA))'), 'field1 background = vv7.L(nz9)');
ok(haj.includes('aVarA.e(2, i, 1)'), 'field2 pageCount int default 1');
ok(haj.includes('aVarA.c(3, oz9Var.I, 0)'), 'field3 bookmarked = oz9.I default 0');
ok(haj.includes('ybg.c(ln2Var)'), 'haj.a validates via ybg.c');

// ---- ln2 字段名实证（toString） ----
ok(ln2.includes('pageCount=" + mmf.a(m())'), 'ln2 field2 named pageCount (mmf wrapper)');
ok(ln2.includes('return 1;'), 'ln2.m() default 1');
ok(ln2.includes('location=" + l()') && ln2.includes('bookmarked=" + k()'),
  'ln2 toString names location/bookmarked');

// ---- haj.c = ln2 再序列化器 ----
ok(haj.includes('public static final int c(ln2 ln2Var, a aVar)'), 'haj.c serializer');
ok(haj.includes('aVar.e(2, iM, 1)') && haj.includes('aVar.c(3, oz9VarK.I, 0)'),
  'haj.c writes same field defaults');

// ---- u5j 掩码 ----
ok(/int i3\) \{\s*if \(\(i3 & 4\) != 0\) \{\s*i2 = 1/.test(u5j.replace(/\n/g, ' ')),
  'u5j.i mask bit2 -> pageCount=1');
ok(/\(i & 2\) != 0\)[^{]*\{\s*num = null/.test(u5j), 'u5j.s mask bit1 -> moveToIndex null');
ok(/\(i & 4\) != 0\)[^{]*\{\s*m2dVar = null/.test(u5j), 'u5j.s mask bit2 -> m2d null');
ok(/\(i & 8\) != 0\)[^{]*\{\s*oz9Var = null/.test(u5j), 'u5j.s mask bit3 -> oz9 null');
ok(u5j.includes('haj.a(cxcVarB, null, i2, oz9.UNBOOKMARKED, 16)'),
  'u5j.i calls haj.a with mask 16');

// ---- 派生默认 ----
ok(u5j.includes('ty0.SQUARE'), 'u5j.f derives ty0.SQUARE');
ok(u5j.includes('ive.PIXEL_ALIGN'), 'u5j.f derives PIXEL_ALIGN');
ok(u5j.includes('t16.FIXED_WIDTH : t16Var'), 'u5j.j defaults t16 FIXED_WIDTH');

// ---- 调用点掩码表 ----
const callers = [
  ['wz9.java', 'haj.a(null, nz9VarB, 1, (oz9) this.f.K, 16)'],
  ['nx6.java', 'haj.a(null, null, 2, null, 27)'],
  ['zm7.java', 'haj.a(cxcVar, null, 1, null, 26)'],
];
for (const [f, needle] of callers) {
  const s = readFileSync(join(SRC, f), 'utf8');
  ok(s.includes(needle), `${f} caller mask ${needle.slice(-6)}`);
}

// ---- haj.b 无关 Compose UI ----
ok(haj.includes('uz4') && haj.includes('fgd.b'), 'haj.b is Compose UI (name collision)');

// ---- Harmony 侧 ----
const enc = readFileSync(join(HARM, 'OriginalCreatePagePayloadEncoder.ets'), 'utf8');
ok(enc.includes('pageCount: number = 1'), 'Harmony encoder pageCount default 1');
ok(enc.includes('haj.a'), 'Harmony encoder cites haj.a');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
