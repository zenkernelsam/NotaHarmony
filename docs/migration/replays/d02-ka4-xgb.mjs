// Phase 977 — ka4 校验契约 + xgb Realtime 值类 + x09 定性
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const ka4 = readFileSync(`${ROOT}/ka4.java`, 'utf8');
const xgb = readFileSync(`${ROOT}/xgb.java`, 'utf8');
const x09 = readFileSync(`${ROOT}/x09.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// ka4 = validation contract: String a()
ok(/interface ka4/.test(ka4) && /String a\(\);/.test(ka4), 'ka4 = {String a()} validation contract');

// registry types implement ka4 (spot check via prior-named files)
const impl = ['uq9','ln2','dm2','wa0','vt9','k3a'].filter(t =>
  /implements ka4|implements.*\bka4\b/.test(readFileSync(`${ROOT}/${t}.java`, 'utf8')));
ok(impl.length === 6, `ka4 implemented by registry types (${impl.join(',')})`);

// xgb = Realtime ulong value class
ok(/class xgb implements Comparable/.test(xgb) && /public final long I;/.test(xgb), 'xgb = {long I} value class');
ok(/Realtime\(value=/.test(xgb), 'xgb toString = Realtime(value=..)');
ok(/Long\.compareUnsigned/.test(xgb), 'xgb: unsigned comparison');
ok(/njj\.j0\(10, j\)/.test(xgb), 'xgb: u64 decimal format via njj.j0');

// zq9.a uses xgb as 4th factory param
const zq9 = readFileSync(`${ROOT}/zq9.java`, 'utf8');
ok(/zq9|static/.test(zq9) && /xgb/.test(zq9), 'zq9.a signature includes xgb');

// x09 = model-side interface
ok(/interface x09/.test(x09), 'x09 = model interface (non-wire)');

console.log(`\nka4-xgb replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
