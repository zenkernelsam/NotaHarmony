import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const leaveStart = page.indexOf('  private async performLeaveEditor(): Promise<void> {');
assert.ok(leaveStart >= 0);
const leaveEnd = page.indexOf('\n  private saveTitle', leaveStart);
assert.ok(leaveEnd > leaveStart);
const leaveBody = page.slice(leaveStart, leaveEnd);

const guardStart = leaveBody.indexOf('if (this.');
const guardEnd = leaveBody.indexOf('{\n      return;', guardStart);
const guard = leaveBody.slice(guardStart, guardEnd);
assert.match(guard, /this\.photoImportLeaseActive \|\| this\.pageStructureLeaseActive/);
const titleSaveIndex = leaveBody.indexOf('if (this.editingTitle)');
assert.ok(titleSaveIndex > guardEnd,
  'leave cannot save title, flush, or navigate during shared ingress');

const commitStart = page.indexOf(
  '  private async commitTitle(requested: string, generation: number): Promise<void> {');
assert.ok(commitStart >= 0);
const commitEnd = page.indexOf('\n  private publishTitleDraft', commitStart);
assert.ok(commitEnd > commitStart);
const commitBody = page.slice(commitStart, commitEnd);

const unchangedPublish = commitBody.indexOf('this.publishTitleDraft(requested, generation);');
const leaseGate = commitBody.indexOf(
  'if (this.photoImportLeaseActive || this.pageStructureLeaseActive) {',
  unchangedPublish,
);
const leaseReturn = commitBody.indexOf('return;', leaseGate);
const repositoryGate = commitBody.indexOf('if (this.noteRepo === null)', leaseReturn);
assert.ok(unchangedPublish >= 0 && leaseGate > unchangedPublish &&
  leaseReturn > leaseGate && repositoryGate > leaseReturn,
  'queued title commits reject shared ingress before repository access');

const inputStart = page.indexOf('TextInput({ text: this.titleDraft })');
assert.ok(inputStart >= 0);
const inputEnd = page.indexOf('\n        } else {', inputStart);
assert.ok(inputEnd > inputStart);
const inputBody = page.slice(inputStart, inputEnd);

for (const callback of ['onSubmit', 'onBlur']) {
  const callbackStart = inputBody.indexOf(`.${callback}(() => {`);
  assert.ok(callbackStart >= 0, `${callback} must remain a direct save boundary`);
  const callbackEnd = inputBody.indexOf('\n            })', callbackStart);
  assert.ok(callbackEnd > callbackStart);
  const callbackBody = inputBody.slice(callbackStart, callbackEnd);
  const leaseGuard = callbackBody.indexOf('if (this.photoImportLeaseActive) {');
  const leaseReturn = callbackBody.indexOf('return;', leaseGuard);
  const titleSave = callbackBody.indexOf('this.saveTitle();', leaseReturn);
  assert.ok(leaseGuard >= 0 && leaseReturn > leaseGuard && titleSave > leaseReturn,
    `${callback} must reject shared ingress before saving the title`);
}

console.log('D02_TITLE_SHARED_INGRESS_LEASE_BOUND_REPLAY_OK TOTAL=12 FAILED=0');
