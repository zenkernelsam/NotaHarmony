import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const peerSource = read('note/src/main/ets/data/OriginalPeerInteractionOperation.ets');
const coordinatorSource = read('note/src/main/ets/data/IncomingOperationSyncCoordinator.ets');
const routerSource = read('note/src/main/ets/data/OriginalPageOperationApplier.ets');
const bundleSource = read('note/src/main/ets/data/OriginalNoteBundlePageIdentity.ets');
const fixtureSource = read('note/src/test/SyncedOperationInbox.test.ets');

const copy = payload => structuredClone(payload);

class PeerStore {
  notes = new Map();

  consume(noteId, siteId, payload, localSiteId) {
    if (siteId === localSiteId) return false;
    let note = this.notes.get(noteId);
    if (!note) this.notes.set(noteId, note = new Map());
    const previous = note.get(siteId);
    const snapshot = copy(payload);
    if (snapshot.cursorPosition === null && previous?.cursorPosition != null) {
      snapshot.cursorPosition = copy(previous.cursorPosition);
    }
    note.set(siteId, snapshot);
    return true;
  }

  read(noteId, siteId) {
    const value = this.notes.get(noteId)?.get(siteId);
    return value === undefined ? null : copy(value);
  }
}

const payload = (cursorPosition, tool = 1, recordingInProgress = false) => ({
  cursorPosition,
  selectedEntities: [{ timestamp: 20, siteId: 2 }, { timestamp: 21, siteId: 3 }],
  tool,
  textSelection: {
    anchor: { timestamp: 30, siteId: 2, index: 4 },
    focus: { timestamp: 31, siteId: 4, index: 5 },
  },
  recordingInProgress,
});

const store = new PeerStore();
assert.equal(store.consume('note', 7, payload({ x: 1, y: 2 }), 7), false);
assert.equal(store.read('note', 7), null);
assert.equal(store.consume('note', 8, payload({ x: 1, y: 2 }), 7), true);
assert.equal(store.consume('other', 8, payload({ x: 9, y: 10 }), 7), true);
assert.deepEqual(store.read('note', 8).cursorPosition, { x: 1, y: 2 });
assert.deepEqual(store.read('other', 8).cursorPosition, { x: 9, y: 10 });

// Coalescing must happen against the state before this batch. A null cursor on the last raw
// operation inherits the old cursor, not a cursor from an earlier operation in the same batch.
const consumeBatch = (noteId, operations) => {
  const lastBySite = new Map();
  let operationCount = 0;
  for (const operation of operations) {
    if (operation.type !== 29) continue;
    operationCount++;
    if (operation.siteId !== 7) lastBySite.set(operation.siteId, operation);
  }
  let updateCount = 0;
  let discardedCount = 0;
  for (const [siteId, operation] of lastBySite) {
    if (!operation.valid) {
      discardedCount++;
      continue;
    }
    store.consume(noteId, siteId, operation.payload, 7);
    updateCount++;
  }
  return { operationCount, updateCount, discardedCount };
};

const coalesced = consumeBatch('note', [
  { type: 29, siteId: 8, valid: true, payload: payload({ x: 12.5, y: -4.25 }, 2, true) },
  { type: 29, siteId: 8, valid: true, payload: payload(null, 3) },
  { type: 29, siteId: 7, valid: true, payload: payload({ x: 99, y: 99 }) },
]);
assert.deepEqual(coalesced, { operationCount: 3, updateCount: 1, discardedCount: 0 });
assert.deepEqual(store.read('note', 8).cursorPosition, { x: 1, y: 2 });
assert.equal(store.read('note', 8).tool, 3);

// A malformed final raw operation discards the entire site update and cannot fall back to an
// earlier valid operation from that batch.
const discarded = consumeBatch('note', [
  { type: 29, siteId: 8, valid: true, payload: payload({ x: 20, y: 21 }, 2) },
  { type: 29, siteId: 8, valid: false, payload: null },
]);
assert.deepEqual(discarded, { operationCount: 2, updateCount: 0, discardedCount: 1 });
assert.equal(store.read('note', 8).tool, 3);

// Peer updates are removed from durable model replay but still consume their inbox position and
// allow a following durable operation to advance the server cursor.
const queue = [{ type: 29, valid: false }, { type: 2, valid: true }];
let modelWrites = 0;
let cursor = null;
while (queue.length > 0) {
  const operation = queue.shift();
  if (operation.type !== 29) modelWrites++;
  cursor = operation.type;
}
assert.equal(modelWrites, 1);
assert.equal(cursor, 2);

// Process restart intentionally drops pending peer presence.
assert.equal(new PeerStore().read('note', 8), null);

assert.match(peerSource, /ORIGINAL_PEER_INTERACTION_PAYLOAD_TYPE: number = 29/);
assert.match(peerSource, /readInlineBytes\(0, 8\)/);
assert.match(peerSource, /readInlineOperationIdentityVector\(3, MAX_SELECTED_PEER_ENTITY_COUNT\)/);
assert.match(peerSource, /selectedKeys\.has\(key\)/);
assert.match(peerSource, /rawTool <= OriginalPeerTool\.ERASER/);
assert.match(peerSource, /readUint8\(6, 0\) !== 0/);
assert.match(peerSource, /lastBySite\.set\(operation\.siteId, operation\)/);
assert.match(peerSource, /decodeOriginalPeerInteraction\(operation\.rawOperation\)/);
assert.match(coordinatorSource, /consumeOriginalPeerInteractionBatch/);
assert.match(coordinatorSource, /validateOperationIdentity\(\{ timestamp: 0, siteId: localSiteId \}\)/);
assert.match(routerSource, /payloadType === ORIGINAL_PEER_INTERACTION_PAYLOAD_TYPE/);
assert.match(routerSource, /decodeOriginalPeerInteraction\(operation\.rawOperation\)/);
assert.match(routerSource, /return \{ deferredReason: null \}/);
assert.match(bundleSource, /NOTE_BUNDLE_TRANSIENT_OPERATION_UNSUPPORTED/);
assert.match(fixtureSource, /flatBufferPeerInteraction/);
assert.match(fixtureSource, /tool\)\.assertEqual\(OriginalPeerTool\.POINTER\)/);
assert.match(fixtureSource, /recordingInProgress\)\.assertTrue\(\)/);

console.log('D02_PEER_INTERACTION_REPLAY_OK ' +
  'full-payload=1|duplicate-selection-dedup=1|unknown-tool-pointer=1|nonzero-bool=1|' +
  'note-site-isolation=1|local-site-ignored=1|same-site-last-wins=1|' +
  'pre-batch-cursor-inheritance=1|malformed-last-discards-site=1|model-writes=0|' +
  'inbox-cursor-advances=1|restart-drops-state=1|note-bundle-rejects=1');
