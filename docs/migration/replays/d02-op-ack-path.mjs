// Phase 861 — 操作回执路径（vq9/be8/ra4/mb9）登记回归
// 证据：docs/migration/evidence/phase-861-op-ack-path.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const HARM = 'note/src/main/ets/data';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

// ---- vq9 OpAck 四字段 ----
const vq9 = readFileSync(join(SRC, 'vq9.java'), 'utf8');
ok(vq9.includes('extends cee implements ka4'), 'vq9 is cee+ka4');
ok(vq9.includes('OpAck(id='), 'vq9 = OpAck');
for (const tok of ['timestampedOp=', 'nakError=', 'duplicate=']) {
  ok(vq9.includes(tok), `vq9 toString names ${tok}`);
}
ok(vq9.includes('c(4)') && vq9.includes('c(6)') && vq9.includes('c(8)') &&
   vq9.includes('c(10)'), 'vq9 fields 0..3 at c(4)/c(6)/c(8)/c(10)');
ok(vq9.includes('uq9'), 'vq9.timestampedOp embeds uq9 Op');

// ---- be8/ra4 JSON change-ack ----
const be8 = readFileSync(join(SRC, 'be8.java'), 'utf8');
ok(be8.includes('ModifyMetadataAck(successfulMutations='), 'be8 = ModifyMetadataAck');
ok(be8.includes('failedMutations='), 'be8 carries failedMutations');
const ra4 = readFileSync(join(SRC, 'ra4.java'), 'utf8');
ok(ra4.includes('aa6Var.T(yxcVar, 0') && ra4.includes('aa6Var.T(yxcVar, 1'),
  'ra4 serializes two string slots');
const ud7 = readFileSync(join(SRC, 'ud7.java'), 'utf8');
ok(ud7.includes('change-ack'), 'ud7 dispatches change-ack');
ok(ud7.includes('Failed to parse change-ack'), 'change-ack has fail-closed parse gate');

// ---- mb9 回显令牌契约 ----
const mb9 = readFileSync(join(SRC, 'mb9.java'), 'utf8');
ok(mb9.includes('expectedAckReply'), 'mb9 reads expectedAckReply');
ok(mb9.includes('acknowledge-appended-ops'), 'mb9 emits acknowledge-appended-ops');

// ---- Harmony acknowledger 等价 ----
const coord = readFileSync(join(HARM, 'IncomingOperationSyncCoordinator.ets'), 'utf8');
ok(coord.includes('IncomingOperationAcknowledger'), 'acknowledger interface exists');
ok(coord.includes('acknowledge(expectedAckReply: string)'), 'echo-token signature kept');
ok(coord.includes('(bundle.expectedAckReply === null) !== (acknowledger === null)'),
  'pairing-invariant gate present');
ok(coord.includes('acknowledge(bundle.expectedAckReply)'), 'ack sent after apply');
ok(coord.includes('incoming operation sync acknowledgement contract is invalid'),
  'contract-violation throw message');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
