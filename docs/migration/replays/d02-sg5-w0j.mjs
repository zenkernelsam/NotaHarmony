// Phase 944 — sg5 草稿池 + jmf + w0j 回归
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const sg5 = rd('sg5.java');
ok(sg5.includes('ThreadLocal'), 'sg5 = ThreadLocal scratch pool');
const REAL_NAMES = [
  ['ID_HOLDER', 'Id'], ['SEQ_ID_HOLDER', 'SeqId'], ['STYLE_MAP_HOLDER', 'StyleMap'],
  ['POINT_HOLDER', 'Point'], ['SIZE_HOLDER', 'Size'], ['MODIFY_POSITION_HOLDER', 'ModifyPosition'],
  ['OP_ACK_HOLDER', 'OpAck'], ['OP_HOLDER', 'Op'],
];
for (const [holder, name] of REAL_NAMES) {
  ok(sg5.includes(`"${holder}"`) && sg5.includes(`flatbuffers/${name}`) ||
     sg5.includes(`flatbuffers.${name}`) || sg5.includes(name),
     `KProperty ${holder} reveals real name ${name}`);
}
ok(sg5.includes('com/gingerlabs/notability/core/flatbuffers/') ||
   sg5.match(/flatbuffers/), 'flatbuffers package path present');
ok(sg5.includes('offsetsHolder') && sg5.includes('usingOffsetsHolder'), 'offset holders registered');
ok(sg5.match(/public static final qo5 a\(\)/), 'sg5.a() = qo5 scratch factory');
ok(sg5.match(/public static final cxc b\(\)/), 'sg5.b() = cxc scratch factory');
ok(sg5.match(/ix4 g\(List/), 'sg5.g = vector writer factory');

ok(rd('jmf.java').includes('interface jmf'), 'jmf = path-vector provider interface');

const w0j = rd('w0j.java');
ok(w0j.match(/static ie8 a\(qo5/) && w0j.match(/d\(ie8 ie8Var, a aVar\)/),
  'w0j = ie8 factory + serializer');
ok(w0j.match(/e\(a aVar, qo5 qo5Var, cxc cxcVar/), 'w0j.e = field writer');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
