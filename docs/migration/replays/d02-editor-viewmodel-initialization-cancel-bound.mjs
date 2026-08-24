import assert from 'node:assert/strict';
import fs from 'node:fs';

const source = fs.readFileSync('note/src/main/ets/ui/editor/EditorViewModel.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const start = source.indexOf('async initialize(');
const end = source.indexOf('\n  getRenderSpec(', start);
assert.ok(start !== -1 && end > start, 'initialize body');
const body = source.slice(start, end);

for (const awaitText of [
  'await this.saveChain;',
  'await repository.getToolStates(ownerId);',
  'await repository.getToolboxState(ownerId);',
  'await settingsRepository.getShapeDetectionEnabled();',
]) {
  const awaitIndex = body.indexOf(awaitText);
  assert.notEqual(awaitIndex, -1, awaitText);
  const guardIndex = body.indexOf('if (!this.isInitializationCurrent()) {', awaitIndex + awaitText.length);
  assert.ok(guardIndex > awaitIndex, `cancel gate after ${awaitText}`);
}

const missingLoopIndex = body.indexOf('for (const state of missing) {');
const missingGuardIndex = body.indexOf('if (!this.isInitializationCurrent()) {', missingLoopIndex);
const missingWriteIndex = body.indexOf('await repository.saveToolState(this.cloneState(state));', missingGuardIndex);
assert.ok(missingLoopIndex !== -1 && missingGuardIndex > missingLoopIndex && missingWriteIndex > missingGuardIndex,
  'missing-state durable write remains cancel-bound');

const callSource = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const initializeCall = callSource.match(/await this\.viewModel\.initialize\([\s\S]*?\);/);
assert.ok(initializeCall, 'NotePage initialization call');
assert.match(initializeCall[0], /'primary-editor'/);
assert.match(initializeCall[0], /editorDisposed/);
assert.match(initializeCall[0], /loadGeneration === this\.pageLoadGeneration/);

console.log('D02_EDITOR_VIEWMODEL_INITIALIZATION_CANCEL_BOUND_REPLAY_OK TOTAL=7 FAILED=0');
