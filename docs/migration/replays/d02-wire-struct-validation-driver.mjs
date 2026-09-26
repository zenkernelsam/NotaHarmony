// Phase 862 — xwd 内联结构 + ybg 校验驱动 + tdf 形状核验回归
// 证据：docs/migration/evidence/phase-862-wire-struct-validation-driver.md
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const HARM = 'note/src/main/ets/data';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

// ---- xwd struct 基座 + 15 子类 ----
const xwd = readFileSync(join(SRC, 'xwd.java'), 'utf8');
ok(xwd.includes('public abstract class xwd'), 'xwd is the struct base');
ok(!xwd.includes('getShort'), 'xwd has no vtable access (fixed-offset struct)');
const xwdSubs = readdirSync(SRC)
  .filter(f => f.endsWith('.java') && readFileSync(join(SRC, f), 'utf8').includes('extends xwd'));
ok(xwdSubs.length === 15, `15 xwd inline structs (got ${xwdSubs.length})`);
for (const c of ['utf', 'qo5']) {
  ok(xwdSubs.includes(c + '.java'), `xwd member ${c} present`);
}

// ---- ybg 校验驱动器 ----
const ybg = readFileSync(join(SRC, 'ybg.java'), 'utf8');
ok(ybg.includes('public static final void c(ka4'), 'ybg.c() ka4 driver exists');
ok(ybg.includes('new ValidationException'), 'ybg throws ValidationException');
ok(ybg.includes('yn7.MODEL'), 'ybg logs at MODEL level');
const zq9 = readFileSync(join(SRC, 'zq9.java'), 'utf8');
ok(zq9.includes('ybg.c(uq9Var)'), 'zq9.a() validates Op right after parse');

// ---- ValidationException 存活类 ----
const ve = readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/core/flatbuffers/ValidationException.java',
  'utf8');
ok(ve.includes('class ValidationException'), 'core/flatbuffers ValidationException exists');

// ---- tdf = {interactionId@0 req, replacedByOp@1 opt} ----
const tdf = readFileSync(join(SRC, 'tdf.java'), 'utf8');
ok(tdf.includes('TransientInteractionEnded(interactionId='), 'tdf = TransientInteractionEnded');
ok(tdf.includes('replacedByOp='), 'tdf carries replacedByOp');
ok(tdf.includes('No value for (required) field interactionId'), 'tdf interactionId required');
ok(tdf.includes('c(4)') && tdf.includes('c(6)'), 'tdf two fields at c(4)/c(6)');

// ---- Harmony 编码器逐字节核验 ----
const enc = readFileSync(join(HARM, 'OriginalTransientInteractionPayloadEncoder.ets'), 'utf8');
ok(enc.includes('new Uint8Array(36)'), 'Harmony tdf payload is 36 bytes');
ok(enc.includes('table: number = 16'), 'Harmony tdf table object = 16 bytes');
ok(enc.includes('replacedByOp === null ? 0 : 12'), 'vtable presence slot for replacedByOp');
ok(enc.includes('writeIdentity(bytes, table + 4, interactionId)'), 'interactionId at +4 (8B qo5)');
ok(enc.includes('writeIdentity(bytes, table + 12, replacedByOp)'), 'replacedByOp at +12 (8B qo5)');
ok(enc.includes('validateOperationIdentity(interactionId)'), 'id validated pre-encode (required)');
ok(/writeU16\(bytes, offset, value\.siteId\)[\s\S]*writeU32\(bytes, offset \+ 4, value\.timestamp\)/
  .test(enc), 'qo5 inline layout: siteId u16@+0 + timestamp u32@+4');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
