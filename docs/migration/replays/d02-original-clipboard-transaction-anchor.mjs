import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = process.env.NOTABILITY_ORIGINAL_ROOT ??
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';

const readRepo = relativePath => fs.readFileSync(path.join(root, relativePath), 'utf8');
const readOriginal = fileName => fs.readFileSync(path.join(originalRoot, fileName), 'utf8');

const lg2 = readOriginal('lg2.java');
const cg2 = readOriginal('cg2.java');
const w43 = readOriginal('w43.java');
const v49 = readOriginal('v49.java');
const g39 = readOriginal('g39.java');
const clipboard = readRepo('note/src/main/ets/rendering/StrokeClipboard.ets');
const canvas = readRepo('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const overlay = readRepo('note/src/main/ets/ui/components/SelectionOverlay.ets');
const fixture = readRepo('note/src/test/StrokeClipboard.test.ets');

const cutBody = lg2.slice(lg2.indexOf('public final java.lang.Object d'),
  lg2.indexOf('public final Object e'));
const cutCopy = cutBody.indexOf('gg2 r8 = g(r9, r8)');
const cutDelete = cutBody.indexOf('x82.I(r9, r1, r4, r3, r0)');
const cutPublish = cutBody.indexOf('r7.a = r8');

const cutBranch = canvas.slice(canvas.indexOf('if (action === SelectionMenuAction.DELETE'),
  canvas.indexOf('} else if (action === SelectionMenuAction.DESELECT)'));
const cutPrepare = cutBranch.indexOf('this.prepareSelectedClipboard(');
const cutQueue = cutBranch.indexOf('this.persistence.queueSaveElements(');
const cutClipboardCommit = cutBranch.indexOf('this.strokeClipboard.commitPreparedCopy(cutPreparation)');
const cutDocumentApply = cutBranch.indexOf('this.completedStrokes = nextStrokes');
const cutHistoryApply = cutBranch.indexOf('this.undoRedo.push(deleteAction, preparedHistory)');

const ordinaryPaste = canvas.slice(canvas.indexOf('private applyClipboardPaste('),
  canvas.indexOf('private createClipboardElementId('));
const pastePrepare = ordinaryPaste.indexOf('this.strokeClipboard.preparePaste(');
const pasteQueue = ordinaryPaste.indexOf('this.persistence.queueSaveElements(');
const pasteCommit = ordinaryPaste.indexOf('this.strokeClipboard.commitPreparedPaste(');
const pasteDocumentApply = ordinaryPaste.indexOf('this.completedStrokes = nextStrokes');
const pasteHistoryApply = ordinaryPaste.indexOf('this.undoRedo.push(action, preparedHistory)');

const checks = [
  ['original Cut snapshots before delete and publishes only after delete succeeds',
    cutCopy >= 0 && cutDelete > cutCopy && cutPublish > cutDelete],
  ['original Copy walks only selected Group descriptors and their descendants',
    lg2.includes('Iterator it2 = arrayList2.iterator()') &&
      lg2.includes('c(set, linkedHashSet2, linkedHashSet3, x09Var, arrayList3')],
  ['original Paste command carries the requested document position',
    w43.includes('new d39(g39Var, j, g8aVar') &&
      v49.includes('new zn3(d8aVar3, j3, cg2Var') &&
      lg2.includes('Object objE = e(cg2Var, j, zn9.f(j, cg2Var.c())')],
  ['original ten-percent capped offset belongs to copied-data duplicate helper',
    cg2.includes('Math.min((f - cmbVar.a) * 0.1f, 30.0f)') &&
      lg2.includes('long jA = cg2VarB.a()')],
  ['original Paste controller suppresses concurrent requests for about 200 ms',
    g39.includes('l.longValue() + 200 >= System.currentTimeMillis()')],
  ['Harmony Cut prepares copy then enqueues future snapshot before publishing or applying UI',
    cutPrepare >= 0 && cutQueue > cutPrepare && cutClipboardCommit > cutQueue &&
      cutDocumentApply > cutClipboardCommit && cutHistoryApply > cutDocumentApply],
  ['Harmony Cut queue failure cancels preparation and returns before publication',
    /catch \(e\) \{[\s\S]*?cancelPreparedCopy\(cutPreparation\)[\s\S]*?reportSaveFailure[\s\S]*?return;/.test(cutBranch)],
  ['Harmony ordinary Paste prepares without consumption then queues before sequence and UI/history commit',
    pastePrepare >= 0 && pasteQueue > pastePrepare && pasteCommit > pasteQueue &&
      pasteDocumentApply > pasteCommit && pasteHistoryApply > pasteDocumentApply],
  ['ordinary Paste no longer performs a second generic persist after its explicit queue',
    !ordinaryPaste.includes('this.persist(originalCreate !== null)')],
  ['prepared Paste is bound to both sequence and published clipboard revision',
    clipboard.includes('clipboardRevision !== this.clipboardRevision || pasteSequence !== this.pasteCount + 1') &&
      clipboard.includes('clipboardRevision: this.clipboardRevision')],
  ['Paste translation uses requested target center and page-edge clamp',
    clipboard.includes('targetCenter.x - sourceCenterX') &&
      clipboard.includes('targetCenter.y - sourceCenterY') &&
      clipboard.includes('Math.max(PAGE_MARGIN - start')],
  ['Copy validates only the Group graph reachable from selected top roots',
    clipboard.includes('const candidates: OriginalSelectionGroup[] | undefined = byId.get(groupId)') &&
      clipboard.includes('candidates === undefined || candidates.length !== 1') &&
      clipboard.includes('if (parentByMember.has(root))')],
  ['Paste availability is live-gated by content load page identity and history state',
    canvas.includes('this.clipboardAvailable && this.strokeClipboard.hasContent() && this.loaded') &&
      canvas.includes('this.loadedPageId === this.currentPage.pageId')],
  ['canvas long press stores a canvas-space anchor and opens native context Paste',
    canvas.includes('this.clipboardPasteTarget = { x: canvasP.x, y: canvasP.y }') &&
      canvas.includes('.bindContextMenu(() => {') && canvas.includes('ResponseType.LongPress')],
  ['selection Paste uses the current selection center rather than a fixed button',
    canvas.includes('private selectionPasteTarget(): Point2D | null') &&
      canvas.includes('(this.selectionRect.left + this.selectionRect.right) / 2') &&
      overlay.includes("items.push({ value: $r('app.string.paste')") &&
      !overlay.includes('standalonePastePosition')],
  ['Harmony applies the original 200 ms request gate',
    canvas.includes('const CLIPBOARD_PASTE_SUPPRESSION_MS: number = 200') &&
      canvas.includes('now - this.lastPasteRequestTime < CLIPBOARD_PASTE_SUPPRESSION_MS')],
  ['ArkTS fixtures cover prepare/commit failure target geometry and unrelated Group corruption',
    fixture.includes('does not publish a prepared Copy until the caller commits it') &&
      fixture.includes('does not consume an ordinary Paste sequence until persistence accepts it') &&
      fixture.includes('rejects a prepared Paste after a newer Copy replaces the clipboard') &&
      fixture.includes('uses the requested target center instead of sequence-based geometry') &&
      fixture.includes('ignores an unrelated malformed Group while copying an independent selection')],
];

function clampAxis(start, end, pageExtent, requestedDelta) {
  const margin = 8;
  const available = pageExtent - margin * 2;
  if (end - start <= available) {
    return Math.max(margin - start, Math.min(requestedDelta, pageExtent - margin - end));
  }
  return margin - start;
}

function simulateCut(initial, queueAccepted) {
  const state = structuredClone(initial);
  const preparedClipboard = structuredClone(state.selection);
  const nextDocument = state.document.filter(id => !state.selection.includes(id));
  if (!queueAccepted) return state;
  state.persisted = nextDocument;
  state.clipboard = preparedClipboard;
  state.document = nextDocument;
  state.history.push({ type: 'DELETE', ids: preparedClipboard });
  return state;
}

const base = {
  document: ['a', 'b', 'c'], selection: ['b'], clipboard: ['old'],
  persisted: ['a', 'b', 'c'], history: [],
};
assert.deepEqual(simulateCut(base, false), base);
assert.deepEqual(simulateCut(base, true), {
  document: ['a', 'c'], selection: ['b'], clipboard: ['b'],
  persisted: ['a', 'c'], history: [{ type: 'DELETE', ids: ['b'] }],
});

assert.equal(clampAxis(10, 30, 200, 85), 85);
assert.equal(clampAxis(180, 190, 200, 10), 2);
assert.equal(clampAxis(2, 12, 200, -20), 6);
assert.equal(clampAxis(0, 300, 200, 50), 8);

for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}

console.log(`D02_ORIGINAL_CLIPBOARD_TRANSACTION_ANCHOR_REPLAY_OK TOTAL=${checks.length + 6} FAILED=0`);
