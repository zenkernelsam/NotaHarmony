// Phase 885 — x09/a79 物化文档模型回归
// 证据：docs/migration/evidence/phase-885-document-model.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const x09 = rd('x09.java');
const a79 = rd('a79.java');
const f1a = rd('f1a.java');

// ---- x09 标记接口 ----
ok(x09.includes('public interface x09') && x09.includes('m09 a = m09.a'),
  'x09 marker interface + m09 companion');

// ---- a79 实现 ----
ok(a79.includes('public final class a79 implements x09'), 'a79 implements x09');
ok((a79.match(/public final yc6 [t-zA]/g) || []).length >= 8,
  'a79 eight yc6 register fields t..A');
ok(a79.includes('public final ye9 b') && a79.includes('public final f1a f') &&
   a79.includes('public final m4c B') && a79.includes('public final nz9 K'),
  'a79 ye9/f1a/m4c/nz9 key fields');

// ---- 七具名属性（KProperty） ----
const props = ['title', 'defaultFontFamily', 'defaultFontSize', 'alignTextToLines',
  'layoutMode', 'blockWrapSupport', 'handwritingLanguage'];
for (const p of props) ok(a79.includes(`"${p}"`), `a79 KProperty ${p}`);
ok(a79.includes('LayoutMode') && a79.includes('BlockWrapSupport'),
  'a79 flatbuffers type names');

// ---- K 背景寄存器 ----
ok(a79.includes('nz9 nz9Var = (nz9) yc6Var7.K') &&
   a79.includes('nz9Var = nz9Var == null ? Q : nz9Var'),
  'a79.K = yc6.w winner nz9 else Q default');

// ---- 静态默认 ----
ok(a79.includes('apb.h(612.0f, 792.0f)'), 'a79.N = qed(612,792) Letter');
ok(a79.includes('fsi.f(36.0f, 36.0f, 36.0f, 36.0f)'), 'a79.O = 36pt margins');
ok(a79.includes('qedVarH.d() / 8.5f'), 'a79.P = N.d/8.5 = 72dpi');
ok(a79.includes('vv7.f(fag.k(null, null, null, (hu1) tu1.a.getValue()'),
  'a79.Q = tu1-color paper default via vv7.f');

// ---- f1a 序模型 ----
ok(f1a.includes('public final class f1a') && f1a.includes('public final rvb b'),
  'f1a {rvb b order source}');
ok((f1a.match(/public final (cl2|oja|q07|kia|int)/g) || []).length >= 6,
  'f1a cl2/oja/q07/kia/int fields');

// ---- 派生调用锚点 ----
ok(rd('u5j.java').includes('((a79) x09Var).f'), 'u5j casts x09 -> a79.f');
ok(rd('bfj.java').includes('svb svbVar'), 'bfj.b consumes f1a.b (svb order)');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
