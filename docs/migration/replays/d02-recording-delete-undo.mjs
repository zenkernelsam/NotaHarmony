import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const originalController = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/kk9.java', 'utf8');
const originalUi = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/n05.java', 'utf8');
const originalStrings = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml', 'utf8');
const controller = read('note/src/main/ets/core/adaptation/OriginalRecordingDeleteController.ets');
const encoder = read('note/src/main/ets/data/OriginalDeleteEntitiesPayloadEncoder.ets');
const store = read('note/src/main/ets/data/OriginalRecordingStore.ets');
const panel = read('note/src/main/ets/ui/editor/RecordingPanel.ets');
const page = read('note/src/main/ets/ui/editor/NotePage.ets');
const opTypes = read('note/src/main/ets/core/model/OpTypes.ets');
const tests = read('note/src/test/OriginalRecordingDeleteController.test.ets');

assert.match(originalController, /Method dump skipped/);
assert.match(originalUi, /pendingDeleteRecordingIds|kpaVar3\.i\.contains/);
assert.match(originalStrings, /feature_note_toolbox__recording_deleted/);
assert.match(originalStrings, /feature_note_toolbox__cd_delete_recording/);
assert.doesNotMatch(originalStrings, /rename_recording|recording_rename/);

assert.match(controller, /ORIGINAL_RECORDING_DELETE_UNDO_MS: number = 10000/);
assert.match(controller, /scheduler\.cancel\(entry\.timer\)/);
assert.match(controller, /this\.startCommit\(scheduled\)/);
assert.match(controller, /await Promise\.all\(this\.commits\.slice\(\)\)/);
assert.match(panel, /PendingDeleteRow/);
assert.match(panel, /recording_deleted/);
assert.match(panel, /onUndoDelete/);
assert.doesNotMatch(panel, /renameRecording|recording_rename/);
assert.match(page, /recordingDeleteController\.flush\(\)/);
assert.match(page, /recordingController\.unload\(\)/);
assert.match(page, /visiblePlaybackRecordings/);

assert.match(store, /editorPersistenceMutex\.runExclusive/);
assert.match(store, /beginTransaction\(\)/);
assert.match(store, /OriginalDeleteEntitiesOperationApplier\(\)\.applyEntityTable/);
assert.match(store, /appendOperation\(store/);
assert.match(store, /uploadImmediately: true/);
assert.match(store, /rollBack\(\)/);
assert.match(opTypes, /ORIGINAL_DELETE_ENTITIES = 60/);
assert.match(encoder, /entityDeletes, entityUndeletes, pageDeletes, pageUndeletes/);
assert.match(tests, /0xFFFFFFFF/);
assert.match(tests, /commits\.length\)\.assertEqual\(0\)/);

// Golden payload: root table field 0 points to a two-entry 8-byte Id vector.
const bytes = encode([{ timestamp: 0xffffffff, siteId: 0xffff }, { timestamp: 7, siteId: 3 }]);
assert.equal(u32(bytes, 0), 16);
const table = 16;
const vtable = table - u32(bytes, table);
assert.equal(u16(bytes, vtable), 12);
assert.equal(u16(bytes, vtable + 4), 4);
assert.equal(u16(bytes, vtable + 6), 0);
const vector = table + 4 + u32(bytes, table + 4);
assert.equal(u32(bytes, vector), 2);
assert.equal(u16(bytes, vector + 4), 0xffff);
assert.equal(u32(bytes, vector + 8), 0xffffffff);
assert.equal(u16(bytes, vector + 12), 3);
assert.equal(u32(bytes, vector + 16), 7);

console.log('recordingDelete=ten-second-undo-batch-lww-payload-journal');

function encode(values) {
  const vector = 36;
  const bytes = new Uint8Array(vector + 4 + values.length * 8);
  w32(bytes, 0, 16); w16(bytes, 4, 12); w16(bytes, 6, 20); w16(bytes, 8, 4);
  w32(bytes, 16, 12); w32(bytes, 20, vector - 20); w32(bytes, vector, values.length);
  values.forEach((value, index) => {
    const offset = vector + 4 + index * 8;
    w16(bytes, offset, value.siteId); w32(bytes, offset + 4, value.timestamp);
  });
  return bytes;
}

function w16(bytes, offset, value) {
  bytes[offset] = value & 255; bytes[offset + 1] = value >>> 8 & 255;
}
function w32(bytes, offset, value) {
  bytes[offset] = value & 255; bytes[offset + 1] = value >>> 8 & 255;
  bytes[offset + 2] = value >>> 16 & 255; bytes[offset + 3] = value >>> 24 & 255;
}
function u16(bytes, offset) { return bytes[offset] | bytes[offset + 1] << 8; }
function u32(bytes, offset) {
  return (bytes[offset] + bytes[offset + 1] * 256 + bytes[offset + 2] * 65536 +
    bytes[offset + 3] * 16777216) >>> 0;
}
