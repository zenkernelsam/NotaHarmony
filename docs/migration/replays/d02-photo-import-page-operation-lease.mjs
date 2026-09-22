#!/usr/bin/env node
import assert from 'node:assert/strict';
import fs from 'node:fs';

const readWindows = (path) => fs.readFileSync(path, 'utf8').replaceAll('\r\n', '\n');
const page = readWindows('note/src/main/ets/ui/editor/NotePage.ets');
const canvas = readWindows('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const fixture = readWindows('note/src/test/PhotoImportPageOperationLease.test.ets');

const toolbarIndex = page.indexOf('onInsertPhotos: () => {');
const leaseStateIndex = page.indexOf('@State photoImportLeaseActive: boolean = false;');
assert.ok(toolbarIndex > 0);
assert.ok(leaseStateIndex > 0);

const gate = page.slice(toolbarIndex, page.indexOf('},\n', toolbarIndex));
assert.match(gate, /photoImportLeaseActive/);
assert.match(gate, /pageOperationBusy/);
assert.match(gate, /historyPending/);
assert.match(gate, /pageStructureLeaseActive/);
assert.match(gate, /this\.photoInsertSignal\+\+/);

const operationStart = page.indexOf('private async runPageOperation(');
const operationBody = page.slice(
  operationStart,
  page.indexOf('private async runPageHistoryOperation', operationStart),
);
assert.match(operationBody, /if \(this\.photoImportLeaseActive \|\| this\.pageOperationBusy \|\| this\.historyPending \|\|/);

assert.match(canvas, /@Prop @Watch\('onPhotoInsertSignalChange'\) photoInsertSignal: number = 0;/);
assert.match(canvas, /@Prop @Watch\('onCameraCaptureSignalChange'\) cameraCaptureSignal: number = 0;/);
assert.match(canvas, /onRequestPage: \(pageId: string\) => void = \(\) => \{\n  \};\n  onPhotoIngressFinished: \(\) => void/);
const finishCount = canvas.match(/this\.onPhotoIngressFinished\(\);/g)?.length ?? 0;
assert.equal(finishCount, 3);
const pickerBusy = canvas.indexOf('private async startOriginalPhotoInsert(): Promise<void> {');
const clipboardBusy = canvas.indexOf('private async startOriginalClipboardImagePaste(): Promise<void> {');
const cameraBusy = canvas.indexOf('private async startOriginalCameraCapture(): Promise<void> {');
for (const start of [pickerBusy, clipboardBusy, cameraBusy]) {
  const finallyIndex = canvas.indexOf('} finally {', start);
  assert.ok(canvas.slice(finallyIndex).includes('this.photoImportBusy = false;'));
  assert.ok(canvas.slice(finallyIndex).includes('this.onPhotoIngressFinished();'));
}

assert.match(fixture, /blocks page structure while photo ingress is active/);
assert.match(fixture, /does not start a second photo ingress/);

console.log('D02_PHOTO_IMPORT_PAGE_OPERATION_LEASE_REPLAY_OK TOTAL=12 FAILED=0');
