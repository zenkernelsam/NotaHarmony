import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = canvas.indexOf('  private async loadNoteData(): Promise<void> {');
const end = canvas.indexOf('  private async readPersistentHistory(', start);
assert.ok(start !== -1 && end > start, 'loadNoteData section exists');
const body = canvas.slice(start, end);

const catchIndex = body.indexOf('    } catch (e) {');
assert.notEqual(catchIndex, -1, 'load failure catch exists');
const generationCheck = body.indexOf('if (generation === this.pageLoadGeneration) {', catchIndex);
assert.notEqual(generationCheck, -1, 'failure path checks captured generation');

const lifecycleGuardIndex = body.indexOf('if (!this.lifecycleActive) {', generationCheck);
const guardEnd = lifecycleGuardIndex === -1 ? -1 : body.indexOf('}', lifecycleGuardIndex);
const lifecycleGuard = lifecycleGuardIndex !== -1 && guardEnd > lifecycleGuardIndex
  ? body.slice(lifecycleGuardIndex, guardEnd + 1).replaceAll(/\s+/g, ' ').trim() : '';
assert.equal(lifecycleGuard, 'if (!this.lifecycleActive) { return; }',
  'disposed editor skips failure reset and toast');

const stateReset = body.indexOf('this.enterLoadFailureState();', generationCheck);
const userReport = body.indexOf('this.reportLoadFailure(e as Object);', generationCheck);
assert.ok(lifecycleGuardIndex !== -1 && stateReset > guardEnd && userReport > guardEnd,
  'lifecycle guard precedes local reset and report');

const finallyIndex = body.indexOf('    } finally {', catchIndex);
assert.ok(finallyIndex > catchIndex, 'load finally exists');
const finallyBody = body.slice(finallyIndex);
assert.match(finallyBody,
  /if \(generation === this\.pageLoadGeneration\) \{\s+this\.dataLoading = false;\s+\}/,
  'same-generation loading cleanup remains authoritative');

console.log('D02_CANVAS_LOAD_FAILURE_LIFECYCLE_BOUND_REPLAY_OK TOTAL=5 FAILED=0');
