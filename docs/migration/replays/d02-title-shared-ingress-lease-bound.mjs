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

console.log('D02_TITLE_SHARED_INGRESS_LEASE_BOUND_REPLAY_OK TOTAL=10 FAILED=0');
