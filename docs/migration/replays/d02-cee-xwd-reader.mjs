// Phase 893 — cee/xwd 读侧基类回归
// 证据：docs/migration/evidence/phase-893-cee-xwd-reader.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const cee = rd('cee.java');
const xwd = rd('xwd.java');

// ---- cee Table 基类 ----
ok(cee.includes('public abstract class cee'), 'cee abstract table base');
ok(cee.includes('public int I') && cee.includes('public ByteBuffer J') &&
   cee.includes('public int K') && cee.includes('public int L'),
  'cee I/J/K/L four state fields');
ok(cee.includes('zq6.i()'), 'cee UTF-8 decoder singleton');
ok(cee.includes('return this.J.getInt(i) + i'), 'cee.b = indirect offset');
ok(cee.includes('i < this.L') && cee.includes('getShort(this.K + i)'),
  'cee.c = vtable slot lookup');
ok(cee.includes('int i2 = i - byteBuffer.getInt(i)') &&
   cee.includes('this.J.getShort(i2)'), 'cee.d vtable start+len assign');
ok(cee.includes('public final String e(int i)'), 'cee.e = __string');
ok(cee.includes('s5c.q('), 'cee.e bounds-check fail path');

// ---- c(4+2i) 双向公式验证 ----
const sw9 = rd('sw9.java');
const wa0 = rd('wa0.java');
ok(/c\(4\)/.test(sw9) || /c\(4\)/.test(wa0), 'readers use c(4) for field0');
ok(wa0.includes('public final String k()') &&
   wa0.includes('public final String m()'), 'wa0 string field accessors');

// ---- xwd Struct 基类 ----
ok(xwd.includes('public abstract class xwd'), 'xwd abstract struct base');
ok(xwd.includes('public int I') && xwd.includes('public ByteBuffer J'),
  'xwd I/J two state fields');
ok(xwd.includes('public final void b(int i, ByteBuffer byteBuffer)'),
  'xwd.b = inline init');
ok(!xwd.includes('public int K'), 'xwd no vtable (inline)');

// ---- 使用点验证：hu1/qed 经 xwd ----
const hu1 = rd('hu1.java');
const qed = rd('qed.java');
ok(hu1.includes('extends xwd'), 'hu1 extends xwd');
ok(qed.includes('extends xwd'), 'qed extends xwd');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
