import assert from 'node:assert/strict';
import fs from 'node:fs';

const controllerSource = fs.readFileSync('note/src/main/ets/core/adaptation/OriginalRecordingDeleteController.ets', 'utf8').replaceAll('\r\n', '\n');
const pageSource = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8').replaceAll('\r\n', '\n');

const startCommitStart = controllerSource.indexOf('private startCommit(recordingIds: string[]): void {');
const publishMethodStart = controllerSource.indexOf('private publish(): void {', startCommitStart);
assert.ok(startCommitStart !== -1 && publishMethodStart > startCommitStart, 'controller methods');
const startCommit = controllerSource.slice(startCommitStart, publishMethodStart);

const finallyIndex = startCommit.lastIndexOf('.finally((): void => {');
const pendingCleanupIndex = startCommit.indexOf('this.pending.delete(recordingId);', finallyIndex);
const commitsCleanupIndex = startCommit.indexOf('this.commits.splice(index, 1);', finallyIndex);
const controllerPublishIndex = startCommit.indexOf('this.publish();', finallyIndex);
assert.ok(finallyIndex !== -1 && pendingCleanupIndex > finallyIndex && commitsCleanupIndex > pendingCleanupIndex &&
  controllerPublishIndex > commitsCleanupIndex, 'commit finally always publishes cleanup');

const listenerStart = pageSource.indexOf('this.recordingDeleteController.setListener((pendingIds: string[]): void => {');
const failureStart = pageSource.indexOf('this.recordingDeleteController.setFailureListener(', listenerStart);
assert.ok(listenerStart !== -1 && failureStart > listenerStart, 'page listener block');
const listener = pageSource.slice(listenerStart, failureStart);
const guardIndex = listener.indexOf('if (this.editorDisposed) {');
const stateIndex = listener.indexOf('this.pendingRecordingDeleteIds = pendingIds;', guardIndex);
const rebuildIndex = listener.indexOf('this.rebuildRecordingTimeline();', stateIndex);
assert.ok(guardIndex !== -1 && stateIndex > guardIndex && rebuildIndex > stateIndex,
  'stale pending publish cannot mutate old editor');

console.log('D02_RECORDING_PENDING_PUBLISH_DISPOSAL_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
