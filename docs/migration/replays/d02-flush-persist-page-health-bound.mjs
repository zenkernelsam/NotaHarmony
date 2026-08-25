import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync(
  'note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');

assert.match(canvas,
  /private isHistoryPageContextCurrent\(generation: number, pageId: string\): boolean \{\s+return this\.lifecycleActive && generation === this\.pageLoadGeneration &&\s+pageId === this\.loadedPageId && pageId === this\.currentPage\.pageId &&\s+this\.loaded && !this\.dataLoading && !this\.dataLoadFailed;\s+\}/);

const flushStart = canvas.indexOf('private async flushCurrentPage');
assert.notEqual(flushStart, -1);
const flushEnd = canvas.indexOf('private async maintainPersistentHistoryCheckpoint', flushStart);
assert.notEqual(flushEnd, -1);
const flushBody = canvas.slice(flushStart, flushEnd);

const temporaryEditorGate = flushBody.indexOf(
  'if (this.mathEditorVisible || this.imageCropVisible) {',
);
assert.notEqual(temporaryEditorGate, -1);
const temporaryEditorReturn = flushBody.indexOf('return false;', temporaryEditorGate);
const textCommitGate = flushBody.indexOf(
  'if (this.textEditing && this.editingTextBlock !== null) {',
  temporaryEditorGate,
);
assert.ok(
  temporaryEditorGate < temporaryEditorReturn &&
    temporaryEditorReturn < textCommitGate,
  'temporary editors fail closed before any flush side effects',
);

// No old 2-line weak guards in flushCurrentPage
const weakInFlush = (flushBody.match(/if \(generation === this\.pageLoadGeneration && pageId === this\.loadedPageId/g) || []).length;
assert.equal(weakInFlush, 0);

// Uses predicate for saveFailed and reportSaveFailure
assert.ok(flushBody.includes(flushBody.includes('isHistoryPageContextCurrent(generation, pageId)')));
assert.ok(flushBody.includes('this.isHistoryPageContextCurrent(generation, pageId)'));

const persistFnStart = canvas.indexOf('private persist(rearmOriginalInk');
assert.notEqual(persistFnStart, -1);
const persistBody = canvas.slice(persistFnStart, persistFnStart + 3000);

// No old weak guards in persist()
const weakInPersist = (persistBody.match(/if \(generation === this\.pageLoadGeneration && pageId === this\.loadedPageId/g) || []).length;
assert.equal(weakInPersist, 0);

// Uses predicate in both success and catch
const predUses = (persistBody.match(/isHistoryPageContextCurrent/g) || []).length;
assert.ok(predUses >= 2);

console.log('D02_FLUSH_PERSIST_PAGE_HEALTH_BOUND_REPLAY_OK TOTAL=10 FAILED=0');
