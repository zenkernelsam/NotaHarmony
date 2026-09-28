// Phase 953 — rh8 线协议三件套：qo5 Id 写器/工厂 + closeFinally
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const rh8 = readFileSync(`${ROOT}/rh8.java`, 'utf8');
const qo5 = readFileSync(`${ROOT}/qo5.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// rh8.O — qo5 8B inline writer, reverse order
ok(/public static final int O\(qo5 qo5Var, a aVar\)/.test(rh8), 'O = qo5 writer');
ok(/aVar\.t\(4, 8\);\s*aVar\.w\(iD\);\s*aVar\.s\(2\);\s*aVar\.y\(sC\);\s*return aVar\.r\(\)/.test(rh8), 'O: t(4,8) w(ts) s(2) y(site) reverse-write');

// rh8.b — qo5 factory (re-read + validate + close)
ok(/public static qo5 b\(int i, short s\)/.test(rh8), 'b = qo5 factory (timestamp,site)');
ok(/aVarA\.p\(aVarA\.r\(\)\)/.test(rh8), 'b: p(r()) finish root');
ok(/qo5Var\.b\(byteBufferWrap/.test(rh8), 'b: re-read via b()');
ok(/ybg\.c\(qo5Var\)/.test(rh8), 'b: ybg.c validation');
ok(/q\(c8dVar, (null|th)\)/.test(rh8), 'b: rh8.q close in both paths');

// rh8.q — closeFinally (Kotlin use)
ok(/public static final void q\(AutoCloseable autoCloseable, Throwable th\)/.test(rh8), 'q = closeFinally');
ok(/s01\.h\(th, th2\)/.test(rh8), 'q: addSuppressed path');
ok(/autoCloseable\.close\(\)/.test(rh8), 'q: direct close');
ok(/awaitTermination\(1L, TimeUnit\.DAYS\)/.test(rh8), 'q: ExecutorService await');

// qo5 = Id{site:UShort@0, timestamp:UInt@4} 8B
ok(/public final class qo5 extends xwd/.test(qo5), 'qo5 = xwd inline struct');
ok(/getShort\(this\.I\)/.test(qo5), 'qo5.c = short @0 (site)');
ok(/getInt\(this\.I \+ 4\)/.test(qo5), 'qo5.d = int @4 (timestamp)');
ok(/"Id\(site=", ymf\.a\(c\(\)\), ", timestamp=", mmf\.a\(d\(\)\)/.test(qo5), 'qo5 toString = Id(site,timestamp) UShort/UInt fmt');
ok(/return null;/.test(qo5) && /String a\(\)/.test(qo5), 'qo5.a() = null (always-valid)');

// packing helpers (non-wire but documented)
ok(/Float\.floatToRawIntBits\(f\) << 32/.test(rh8), 'a(f,f) = 2-float->long pack');

console.log(`\nrh8-id-writer replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
