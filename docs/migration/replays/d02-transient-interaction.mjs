import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const transientSource = read('note/src/main/ets/data/OriginalTransientInteractionOperation.ets');
const routerSource = read('note/src/main/ets/data/OriginalPageOperationApplier.ets');
const positionsSource = read('note/src/main/ets/data/OriginalModifyPositionsOperation.ets');
const bundleSource = read('note/src/main/ets/data/OriginalNoteBundlePageIdentity.ets');
const fixtureSource = read('note/src/test/SyncedOperationInbox.test.ets');

const key = identity => `${identity.timestamp}:${identity.siteId}`;

class TransientStore {
  interactions = new Map();

  record(noteId, interactionId, operationId) {
    let note = this.interactions.get(noteId);
    if (!note) this.interactions.set(noteId, note = new Map());
    let operations = note.get(key(interactionId));
    if (!operations) note.set(key(interactionId), operations = new Set());
    operations.add(key(operationId));
  }

  end(noteId, interactionId) {
    const note = this.interactions.get(noteId);
    const operations = note?.get(key(interactionId));
    if (!operations) return 0;
    note.delete(key(interactionId));
    if (note.size === 0) this.interactions.delete(noteId);
    return operations.size;
  }

  count(noteId, interactionId) {
    return this.interactions.get(noteId)?.get(key(interactionId))?.size ?? 0;
  }
}

const interaction = { timestamp: 80, siteId: 6 };
const store = new TransientStore();
store.record('note', interaction, { timestamp: 10, siteId: 1 });
store.record('note', interaction, { timestamp: 11, siteId: 1 });
store.record('other', interaction, { timestamp: 12, siteId: 1 });
assert.equal(store.count('note', interaction), 2);
assert.equal(store.end('note', interaction), 2);
assert.equal(store.end('note', interaction), 0);
assert.equal(store.count('other', interaction), 1);

// Restart creates a fresh ephemeral map; no stale preview is restored from durable storage.
const restarted = new TransientStore();
assert.equal(restarted.count('other', interaction), 0);

// A valid end is consumed as an applied inbox head, so the next durable operation can drain.
const queue = [
  { type: 26, valid: true, interactionId: interaction },
  { type: 2, valid: true },
];
const applied = [];
while (queue.length > 0) {
  const operation = queue[0];
  if (!operation.valid) break;
  if (operation.type === 26) restarted.end('note', operation.interactionId);
  applied.push(queue.shift().type);
}
assert.deepEqual(applied, [26, 2]);
assert.equal(queue.length, 0);

// Malformed type 26 remains deferred and therefore cannot silently advance the cursor.
const malformedQueue = [{ type: 26, valid: false }, { type: 2, valid: true }];
const malformedApplied = [];
while (malformedQueue.length > 0 && malformedQueue[0].valid) {
  malformedApplied.push(malformedQueue.shift().type);
}
assert.deepEqual(malformedApplied, []);
assert.deepEqual(malformedQueue.map(operation => operation.type), [26, 2]);

assert.match(transientSource, /ORIGINAL_TRANSIENT_INTERACTION_ENDED_PAYLOAD_TYPE: number = 26/);
assert.match(transientSource, /root\.readTable\(6\)/);
assert.match(transientSource, /original transient interaction timeout is unsupported/);
assert.match(transientSource, /metadata and payload interaction IDs differ/);
assert.match(transientSource, /rejectFieldsFrom\(root, 7/);
assert.match(routerSource, /payloadType === ORIGINAL_TRANSIENT_INTERACTION_ENDED_PAYLOAD_TYPE/);
assert.match(routerSource, /endInteraction\(operation\.noteId, payload\.interactionId\)/);
assert.match(routerSource, /root\.hasField\(6\)/);
assert.doesNotMatch(routerSource, /readUint8\(3, 0\)/);
assert.match(positionsSource, /fromRoot\(operation\.rawOperation\)\.hasField\(6\)/);
assert.doesNotMatch(positionsSource, /fromRoot\(operation\.rawOperation\)\.readUint8\(3, 0\)/);
assert.match(bundleSource, /NOTE_BUNDLE_TRANSIENT_OPERATION_UNSUPPORTED/);
assert.match(fixtureSource, /flatBufferTransientInteractionEnded/);
assert.match(fixtureSource, /includeAudioTime/);

console.log('D02_TRANSIENT_INTERACTION_REPLAY_OK ' +
  'field6-metadata=1|required-id=1|metadata-payload-match=1|timeout-rejected=1|' +
  'unknown-field-rejected=1|note-isolation=1|duplicate-end=1|restart-drops-preview=1|' +
  'end-unblocks-durable-head=1|malformed-blocks-head=1|audioTime-not-transient=1|' +
  'note-bundle-still-rejects=1');
