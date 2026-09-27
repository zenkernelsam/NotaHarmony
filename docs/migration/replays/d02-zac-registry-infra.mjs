// Phase 896 — zac 会话基类 + 注册基建回归
// 证据：docs/migration/evidence/phase-896-zac-registry-infra.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const zac = rd('zac.java');
const npb = rd('npb.java');
const mpb = rd('mpb.java');
const wx4 = rd('wx4.java');
const zwd = rd('zwd.java');
const tzc = rd('tzc.java');

// ---- zac ----
ok(zac.includes('public abstract class zac implements Closeable'),
  'zac Closeable base');
ok(zac.includes('AtomicBoolean(false)'), 'zac AtomicBoolean state');
ok(zac.includes('public abstract void a()'), 'zac abstract a()');
ok(zac.includes('compareAndSet(false, true)') &&
   zac.includes('public final void close()'), 'zac idempotent close');
ok(zac.includes('public final void finalize()'), 'zac finalize fallback');
ok(tzc.includes('extends zac'), 'tzc extends zac');

// ---- npb/mpb ----
ok(npb.includes('public oj6 b(Class cls)'), 'npb.b Class->KClass key');
ok(npb.includes('new gn1(cls)'), 'npb.b impl = gn1');
ok(mpb.includes('public static final npb a') &&
   mpb.includes('opb.class.newInstance()'), 'mpb lazy opb provider');
ok(mpb.includes('npbVar = new npb()'), 'mpb fallback to base npb');

// ---- wx4 Function2 ----
ok(wx4.includes('public interface wx4 extends xx4') &&
   wx4.includes('Object invoke(Object obj, Object obj2)'),
  'wx4 = Function2 serializer lambda');

// ---- zwd 注册表联动 ----
ok(zwd.includes('npbVar.b(cls)') && zwd.includes('wx4Var.invoke'),
  'zwd.a registry = KClass->Function2');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
