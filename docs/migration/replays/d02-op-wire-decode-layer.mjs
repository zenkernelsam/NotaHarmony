// Phase 858 — FlatBuffer 读取基座 cee 与同步信封解码层登记回归
// 证据：docs/migration/evidence/phase-858-op-wire-decode-layer.md
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const HARM = 'note/src/main/ets/data';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

// ---- cee 读取基座 ----
const cee = readFileSync(join(SRC, 'cee.java'), 'utf8');
ok(cee.includes('public final void d(int i, ByteBuffer'), 'cee.d() vtable init exists');
ok(cee.includes('byteBuffer.getInt(i)') && cee.includes('getShort'), 'cee.d() uses vtable-offset math');
ok(cee.includes('public final String e(int i)'), 'cee.e() UTF-8 decode exists');
ok((cee.match(/public final/g) || []).length >= 5, 'cee exposes >=5 reader helpers');

const ceeSubs = readdirSync(SRC)
  .filter(f => f.endsWith('.java') && readFileSync(join(SRC, f), 'utf8').includes('extends cee'));
ok(ceeSubs.length === 67, `67 cee reader subclasses (got ${ceeSubs.length})`);

// ---- p9 AcknowledgeAppendedOpsEvent ----
const p9 = readFileSync(join(SRC, 'p9.java'), 'utf8');
ok(p9.includes('extends cee implements ka4'), 'p9 is a cee+ka4 table');
ok(p9.includes('AcknowledgeAppendedOpsEvent(acks='), 'p9 = AcknowledgeAppendedOpsEvent');
ok(/c\(4\)/.test(p9), 'p9 reads acks vector at field 4');
ok(p9.includes('vq9'), 'p9 acks elements are vq9');

// ---- mb9 ops-socket session ----
const mb9 = readFileSync(join(SRC, 'mb9.java'), 'utf8');
ok(mb9.includes('receive-ops'), 'mb9 handles receive-ops');
ok(mb9.includes('acknowledge-appended-ops'), 'mb9 emits acknowledge-appended-ops');
ok(mb9.includes('expectedAckReply'), 'mb9 reads expectedAckReply JSON field');
ok(mb9.includes('Missing expectedAckReply in receive-ops'), 'mb9 missing-ack-reply log gate');

// ---- ud7 socket dispatch ----
const ud7 = readFileSync(join(SRC, 'ud7.java'), 'utf8');
ok(ud7.includes('change-ack'), 'ud7 dispatches change-ack (JSON path)');
ok(ud7.includes('Failed to parse byte array into AcknowledgeAppendedOpsEvent'),
  'ud7 binary path parses into p9');

// ---- Harmony 读取器等价 ----
const reader = readFileSync(join(HARM, 'OriginalSyncedOperationFlatBuffer.ets'), 'utf8');
ok(reader.includes('class OriginalFlatBufferTableReader'), 'OriginalFlatBufferTableReader exists');
for (const m of ['readUint8', 'readUint16', 'readUint32', 'readFloat32',
                 'readUtf8String', 'readTableVectorAsRoots', 'readInlineBytes']) {
  ok(reader.includes(m), `reader has ${m}`);
}
ok(reader.includes('requireObjectBytes'), 'reader has bounds gate requireObjectBytes');

// ---- Harmony 信封解码 ----
const coord = readFileSync(join(HARM, 'IncomingOperationSyncCoordinator.ets'), 'utf8');
ok(coord.includes('decodeOriginalOpsBundle'), 'ops-bundle decoder exists');
ok(coord.includes('decodeOriginalReceiveOpsEvent'), 'receive-ops-event decoder exists');
ok(/readTableVectorAsRoots\(\s*0/.test(coord), 'ops vector at field 0');
ok(/readUint16\(1, 0\)/.test(coord), 'bundle schemaVersion at field 1 (u16)');
ok(coord.includes('readUtf8String(1, true'), 'receive-ops expectedAckReply field 1 required');
ok(coord.includes('has no expected ACK reply'), 'missing-ack-reply throw mirrors original log gate');
ok(/readUint16\(2, 0\)/.test(coord), 'event schemaVersion at field 2');
ok(coord.includes('MAX_INCOMING_OPERATION_COUNT'), 'incoming-op count bound');
ok(coord.includes('MAX_ACK_REPLY_BYTES'), 'ack-reply byte bound');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
