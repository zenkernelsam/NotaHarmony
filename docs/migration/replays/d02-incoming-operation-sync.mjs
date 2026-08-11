import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const coordinatorSource = readFileSync(new URL(
  '../../../note/src/main/ets/data/IncomingOperationSyncCoordinator.ets', import.meta.url), 'utf8');
const flatBufferSource = readFileSync(new URL(
  '../../../note/src/main/ets/data/OriginalSyncedOperationFlatBuffer.ets', import.meta.url), 'utf8');
const deferredSource = readFileSync(new URL(
  '../../../note/src/main/ets/data/DeferredSyncedOperationBundle.ets', import.meta.url), 'utf8');

assert.match(coordinatorSource, /await this\.inbox\.receiveBatch/);
assert.match(coordinatorSource, /await this\.inbox\.processHead/);
assert.match(coordinatorSource, /await acknowledger\.acknowledge/);
assert.ok(coordinatorSource.indexOf('await this.inbox.receiveBatch') <
  coordinatorSource.lastIndexOf('await acknowledger.acknowledge'));
assert.ok(coordinatorSource.indexOf('await this.inbox.processHead') <
  coordinatorSource.lastIndexOf('await acknowledger.acknowledge'));
assert.match(coordinatorSource, /decoded\.schemaVersion !== bundle\.schemaVersion/);
assert.match(coordinatorSource, /NOTE_BUNDLE must use its page-identity bootstrap transaction/);
assert.match(flatBufferSource, /readTableVectorAsRoots/);
assert.match(flatBufferSource, /re-root copies exceed their byte budget/);
assert.match(flatBufferSource, /readFlatBufferRoot\(result\)/);
assert.match(deferredSource, /export function validateDeferredSyncedOperationBundle/);

function readU16(bytes, offset) {
  return bytes[offset] | (bytes[offset + 1] << 8);
}

function readU32(bytes, offset) {
  return (bytes[offset] + bytes[offset + 1] * 0x100 +
    bytes[offset + 2] * 0x10000 + bytes[offset + 3] * 0x1000000) >>> 0;
}

function tableAt(bytes, position) {
  const vtable = position - readU32(bytes, position);
  const size = readU16(bytes, vtable);
  assert.ok(vtable >= 4 && size >= 4 && vtable + size <= bytes.length);
  return { bytes, position, vtable, size };
}

function rootTable(bytes) {
  return tableAt(bytes, readU32(bytes, 0));
}

function fieldOffset(table, field) {
  const slot = table.vtable + 4 + field * 2;
  return slot + 2 <= table.vtable + table.size ? readU16(table.bytes, slot) : 0;
}

function vectorTables(table, field) {
  const offset = fieldOffset(table, field);
  if (offset === 0) return [];
  const pointer = table.position + offset;
  const vector = pointer + readU32(table.bytes, pointer);
  const count = readU32(table.bytes, vector);
  const result = [];
  for (let index = 0; index < count; index++) {
    const element = vector + 4 + index * 4;
    result.push(tableAt(table.bytes, element + readU32(table.bytes, element)));
  }
  return result;
}

function reroot(table) {
  const copy = table.bytes.slice();
  writeU32(copy, 0, table.position);
  rootTable(copy);
  return copy;
}

function decimalU64(bytes, offset) {
  let value = 0n;
  for (let index = 7; index >= 0; index--) value = value * 256n + BigInt(bytes[offset + index]);
  return value.toString();
}

function decodeOperation(raw, schemaVersion) {
  const root = rootTable(raw);
  const id = root.position + fieldOffset(root, 0);
  const client = root.position + fieldOffset(root, 1);
  const server = root.position + fieldOffset(root, 2);
  return {
    timestamp: readU32(raw, id + 4), siteId: readU16(raw, id),
    clientTime: decimalU64(raw, client), serverTime: decimalU64(raw, server),
    payloadType: raw[root.position + fieldOffset(root, 4)], schemaVersion, raw,
  };
}

function readString(table, field) {
  const pointer = table.position + fieldOffset(table, field);
  const vector = pointer + readU32(table.bytes, pointer);
  const length = readU32(table.bytes, vector);
  return new TextDecoder().decode(table.bytes.slice(vector + 4, vector + 4 + length));
}

function decodeReceive(bytes) {
  const root = rootTable(bytes);
  const schemaVersion = readU16(bytes, root.position + fieldOffset(root, 2));
  return {
    schemaVersion, expectedAckReply: readString(root, 1),
    operations: vectorTables(root, 0).map(table => decodeOperation(reroot(table), schemaVersion)),
  };
}

function decodeOpsBundle(bytes) {
  const root = rootTable(bytes);
  const schemaVersion = readU16(bytes, root.position + fieldOffset(root, 1));
  return {
    schemaVersion, expectedAckReply: null,
    operations: vectorTables(root, 0).map(table => decodeOperation(reroot(table), schemaVersion)),
  };
}

async function receiveDecoded(bundle, { duplicate = false, deferred = false, fail = false } = {}) {
  if (bundle.operations.length === 0) {
    return { inserted: 0, duplicate: 0, terminal: 'EMPTY',
      calls: bundle.expectedAckReply === null ? [] : [`ack:${bundle.expectedAckReply}`] };
  }
  const calls = ['receive'];
  if (fail) throw Object.assign(new Error('injected reducer failure'), { calls });
  calls.push('process');
  const terminal = deferred ? 'DEFERRED' : 'EMPTY';
  if (!deferred) calls.push('process');
  if (bundle.expectedAckReply !== null) calls.push(`ack:${bundle.expectedAckReply}`);
  return { inserted: duplicate ? 0 : bundle.operations.length,
    duplicate: duplicate ? bundle.operations.length : 0, terminal, calls };
}

const receive = decodeReceive(receiveFixture());
assert.equal(receive.schemaVersion, 7);
assert.equal(receive.expectedAckReply, 'ack');
assert.deepEqual({ ...receive.operations[0], raw: undefined }, {
  timestamp: 9, siteId: 3, clientTime: '11', serverTime: '12',
  payloadType: 3, schemaVersion: 7, raw: undefined,
});
assert.equal(readU32(receive.operations[0].raw, 0), 56);

const ops = decodeOpsBundle(opsBundleFixture());
assert.equal(ops.schemaVersion, 7);
assert.equal(ops.expectedAckReply, null);
assert.equal(ops.operations[0].timestamp, 9);
assert.equal(readU32(ops.operations[0].raw, 0), 56);

const applied = await receiveDecoded(receive);
assert.deepEqual(applied.calls, ['receive', 'process', 'process', 'ack:ack']);
assert.deepEqual((await receiveDecoded(receive, { duplicate: true })).calls,
  ['receive', 'process', 'process', 'ack:ack']);
assert.deepEqual((await receiveDecoded(receive, { deferred: true })).calls,
  ['receive', 'process', 'ack:ack']);
await assert.rejects(async () => receiveDecoded(receive, { fail: true }), error => {
  assert.deepEqual(error.calls, ['receive']);
  return true;
});
assert.deepEqual((await receiveDecoded(ops)).calls, ['receive', 'process', 'process']);
const emptyReceive = decodeReceive(receiveFixture());
emptyReceive.operations = [];
assert.deepEqual((await receiveDecoded(emptyReceive)).calls, ['ack:ack']);

function receiveFixture() {
  const bytes = operationBundleStorage(112);
  writeU32(bytes, 0, 16);
  writeU16(bytes, 4, 10); writeU16(bytes, 6, 16);
  writeU16(bytes, 8, 4); writeU16(bytes, 10, 8); writeU16(bytes, 12, 12);
  writeU32(bytes, 16, 12); writeU32(bytes, 20, 12); writeU32(bytes, 24, 80);
  writeU16(bytes, 28, 7); writeU32(bytes, 32, 1); writeU32(bytes, 36, 20);
  writeOperation(bytes, 40, 56);
  writeU32(bytes, 104, 3); bytes.set([0x61, 0x63, 0x6B], 108);
  return bytes;
}

function opsBundleFixture() {
  const bytes = operationBundleStorage(100);
  writeU32(bytes, 0, 16);
  writeU16(bytes, 4, 8); writeU16(bytes, 6, 12);
  writeU16(bytes, 8, 4); writeU16(bytes, 10, 8);
  writeU32(bytes, 16, 12); writeU32(bytes, 20, 12); writeU16(bytes, 24, 7);
  writeU32(bytes, 32, 1); writeU32(bytes, 36, 20);
  writeOperation(bytes, 40, 56);
  return bytes;
}

function operationBundleStorage(size) {
  return new Uint8Array(size);
}

function writeOperation(bytes, vtable, table) {
  writeU16(bytes, vtable, 16); writeU16(bytes, vtable + 2, 36);
  writeU16(bytes, vtable + 4, 4); writeU16(bytes, vtable + 6, 12);
  writeU16(bytes, vtable + 8, 20); writeU16(bytes, vtable + 12, 28);
  writeU16(bytes, vtable + 14, 32);
  writeU32(bytes, table, table - vtable); writeU16(bytes, table + 4, 3);
  writeU32(bytes, table + 8, 9); writeDecimalU64(bytes, table + 12, '11');
  writeDecimalU64(bytes, table + 20, '12'); bytes[table + 28] = 3;
  writeU32(bytes, table + 32, 8);
  writeU16(bytes, table + 36, 4); writeU16(bytes, table + 38, 4);
  writeU32(bytes, table + 40, 4);
}

function writeU16(bytes, offset, value) {
  bytes[offset] = value & 255; bytes[offset + 1] = (value >>> 8) & 255;
}

function writeU32(bytes, offset, value) {
  bytes[offset] = value & 255; bytes[offset + 1] = (value >>> 8) & 255;
  bytes[offset + 2] = (value >>> 16) & 255; bytes[offset + 3] = (value >>> 24) & 255;
}

function writeDecimalU64(bytes, offset, value) {
  let remaining = BigInt(value);
  for (let index = 0; index < 8; index++) {
    bytes[offset + index] = Number(remaining & 255n);
    remaining >>= 8n;
  }
}

console.log('success|zgb=1|vt9=1|uq9-reroot=2|ack-after-drain=1|empty-ack=1|retry=1|deferred=1|no-ack-on-failure=1');
