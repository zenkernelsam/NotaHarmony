import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const ink = read('note/src/main/ets/data/OriginalCreateInkOperation.ets');
const shape = read('note/src/main/ets/data/OriginalShapeGroupOperation.ets');
const block = read('note/src/main/ets/data/OriginalCreateBlockOperation.ets');
const text = read('note/src/main/ets/data/OriginalInsertTextOperation.ets');
const batch = read('note/src/main/ets/data/OriginalPageMutationBatch.ets');
const fixtures = read('note/src/test/SyncedOperationInbox.test.ets');
const originalPaste = original('sources/defpackage/lg2.java');

assert.match(originalPaste, /u5j\.c\(x09Var,/);
assert.match(originalPaste, /\(\(uq9\) next\)\.m\(\) == haa\.CREATE_GROUP/);

assert.match(ink, /async applyBatchedPayload\([\s\S]*?revisionBatch: OriginalPageMutationBatch/);
assert.match(ink, /target\.revision \+ 1, revisionBatch/);
assert.match(ink, /revisionBatch\.recordInk\(batchTarget\)/);
assert.match(shape, /async applyCreateShapeBatchedPayload\([\s\S]*?revisionBatch: OriginalPageMutationBatch/);
assert.match(shape, /operation\.payloadType !== ORIGINAL_CREATE_SHAPE_PAYLOAD_TYPE/);
assert.match(shape, /batch\.recordBlock\(target, false\)/);
assert.match(shape, /if \(revisionBatch === null\) \{\s*await batch\.flush/);
assert.match(block, /async applyBatchedPayload\([\s\S]*?revisionBatch: OriginalPageMutationBatch/);
assert.match(text, /async applyBatchedPayload\([\s\S]*?revisionBatch: OriginalPageMutationBatch/);
assert.match(batch, /predicates\.equalTo\('content_revision', target\.revision\)/);
assert.match(batch, /'content_revision': target\.revision \+ 1/);
assert.match(fixtures, /batches mixed create page revisions and search invalidation once/);
assert.match(fixtures, /batch\.recordInk\(target\);[\s\S]*?batch\.recordBlock\(target, true\);[\s\S]*?batch\.recordBlock\(target, false\)/);
assert.match(fixtures, /expect\(updates\)\.assertEqual\(1\)/);

class RevisionBatchModel {
  constructor() {
    this.pages = new Map();
  }
  record(page, kind) {
    const entry = this.pages.get(page) ?? { ink: false, text: false };
    entry.ink ||= kind === 'ink';
    entry.text ||= kind === 'text';
    this.pages.set(page, entry);
  }
  flush(revisions) {
    for (const page of this.pages.keys()) {
      revisions.set(page, revisions.get(page) + 1);
    }
  }
}

const model = new RevisionBatchModel();
const revisions = new Map([['page', 7]]);
model.record('page', 'ink');
model.record('page', 'text');
model.record('page', 'shape');
model.flush(revisions);
assert.equal(revisions.get('page'), 8);
assert.deepEqual(model.pages.get('page'), { ink: true, text: true });

console.log('originalCreateLeafRevisionBatch=' +
  'ink-shape-block-text-shared-cas-single-revision-search-invalidation');
