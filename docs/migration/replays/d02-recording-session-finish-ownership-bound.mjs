import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const read = (relativePath) => fs.readFileSync(path.join(root, relativePath), 'utf8');

const page = read('note/src/main/ets/ui/editor/NotePage.ets')
  .replaceAll('\r\n', '\n');
const controller = read(
  'note/src/main/ets/core/adaptation/OriginalRecordingSessionController.ets');

const finishStart = page.indexOf('private async finishRecordingSession(): Promise<boolean> {');
const toggleStart = page.indexOf('private async toggleRecording(', finishStart);
assert.ok(finishStart >= 0 && toggleStart > finishStart);
const finish = page.slice(finishStart, toggleStart);

const disappearStart = page.indexOf('aboutToDisappear(): void {');
const backPressStart = page.indexOf('onBackPress(): boolean {', disappearStart);
assert.ok(disappearStart >= 0 && backPressStart > disappearStart);
const disappear = page.slice(disappearStart, backPressStart);

const performStart = page.indexOf('private async performLeaveEditor(): Promise<void> {');
const loadPagesStart = page.indexOf('private async loadPages(): Promise<void> {', performStart);
assert.ok(performStart >= 0 && loadPagesStart > performStart);
const perform = page.slice(performStart, loadPagesStart);

const checks = [
  ['finish captures the owned session before clearing the page pointer',
    (() => {
      const local = finish.indexOf('const session:');
      const branch = finish.indexOf('if (session === null) {', local);
      const clear = finish.indexOf('this.recordingSessionController = null;', branch);
      const cancel = finish.indexOf('this.cancelRecordingSessionRefresh();', clear);
      const release = finish.indexOf('await session.finishAndRelease();', cancel);
      return ordered(local, branch, clear, cancel, release);
    })()],
  ['a second page-side finish cannot observe the same session',
    finish.includes('if (session === null) {\n      return true;\n    }') &&
    /recordingSessionController = null;[\s\S]*?await session\.finishAndRelease\(\)/.test(finish)],
  ['session refresh is cancelled before terminal release',
    ordered(
      finish.indexOf('this.cancelRecordingSessionRefresh();'),
      finish.indexOf('await session.finishAndRelease();'))],
  ['release failures remain fail-visible instead of being swallowed',
    finish.includes('console.warn(`Recording session release failed:') &&
    finish.includes('return false;')],
  ['page disposal cancels the timer before fire-and-forget finishing',
    ordered(
      disappear.indexOf('this.editorDisposed = true;'),
      disappear.indexOf('this.cancelRecordingSessionRefresh();'),
      disappear.indexOf('this.finishRecordingSession();'))],
  ['leave awaits session teardown before releasing playback and navigating',
    ordered(
      perform.indexOf('await this.recordingDeleteController.flush();'),
      perform.indexOf('if (this.editorDisposed) {', perform.indexOf('flush();')),
      perform.indexOf('await this.finishRecordingSession();'),
      perform.indexOf('await this.recordingController.release();'),
      perform.indexOf('router.back();'))],
  ['controller serializes start/control/stop/release through one mutex',
    controller.match(/async mutex|new AsyncMutex/g)?.length === 1 &&
    [...controller.matchAll(/mutex\.runExclusive/g)].length >= 5],
  ['terminal released gate rejects later controls without touching capture again',
    ordered(
      controller.indexOf('async finishAndRelease()'),
      controller.indexOf('if (this.released) {', controller.indexOf('finishAndRelease')),
      controller.indexOf('this.released = true;', controller.indexOf('finishAndRelease'))) &&
    /async start\(source: OriginalRecordingAudioSource =[\s\S]{0,700}if \(this\.released \|\|/.test(controller)],
  ['queued interruption stop cannot run after terminal release',
    controller.indexOf('onCaptureInterrupted') < controller.length &&
    /onCaptureInterrupted\(\): void \{[\s\S]*?this\.stop\(\)/.test(controller) &&
    /async stop\(\): Promise<boolean> \{[\s\S]*?runExclusive[\s\S]*?return await this\.stopInternal\(\);/.test(controller)],
  ['terminal publication clears its listener after the final snapshot',
    ordered(
      controller.indexOf('this.publish();', controller.indexOf('finishAndRelease')),
      controller.indexOf('this.listener = null;', controller.indexOf('finishAndRelease')))],
  ['post-dialog starts are gated by current disposal ownership',
    (() => {
      const start = page.indexOf('private async startRecording(): Promise<void> {');
      const end = page.indexOf('private async pauseRecording()', start);
      assert.ok(start >= 0 && end > start);
      const method = page.slice(start, end);
      const firstDialog = method.indexOf('promptAction.showDialog');
      const microphone = method.indexOf('OriginalRecordingAudioSource.MICROPHONE)', firstDialog);
      const internal = method.indexOf('OriginalRecordingAudioSource.DEVICE_ONLY)', microphone);
      const firstGuard = method.indexOf('if (this.editorDisposed) {', firstDialog);
      const secondGuard = method.indexOf('if (this.editorDisposed) {', microphone);
      return ordered(firstDialog, firstGuard, microphone, secondGuard, internal);
    })()],
];

function ordered(...indexes) {
  return indexes.every(index => index >= 0) &&
    indexes.every((index, position) => position === 0 || index > indexes[position - 1]);
}

for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
