import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');

const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const queue = read('note/src/main/ets/data/LatestWriteQueue.ets');
const undo = read('note/src/main/ets/rendering/UndoRedoManager.ets');

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');
const haa = original('haa.java');
const cm2 = original('cm2.java');
const vd8 = original('vd8.java');
const v69 = original('v69.java');
const de2 = original('de2.java');
const ud2 = original('ud2.java');
const qd2 = original('qd2.java');

assert.match(haa, /CREATE_GROUP\(\(byte\) 20\)/);
assert.match(cm2, /Cannot create a group with 0 members/);
assert.match(vd8, /Must specify more than 0 members/);
assert.match(v69,
  /iOrdinal3 == 20[\s\S]{0,500}j0\.p\(uq9Var5\)[\s\S]{0,900}au1\.O0\(set5, arrayList18\)/);
assert.match(de2, /asd asdVarA = bsd\.a\(new qd2\(\)\)/);
assert.match(ud2, /Integer num = \(Integer\) obj/);
assert.match(qd2, /UiState\(currentPageIndex=/);

const staleContextGuard = String.raw`generation === this.pageLoadGeneration && pageId === this.loadedPageId &&
\s+pageId === this.currentPage.pageId && this.loaded && !this.dataLoading &&
\s+!this.dataLoadFailed`;
const persistedStaleContextGuard = String.raw`persistedGeneration === this.pageLoadGeneration &&
\s+persistedPageId === this.loadedPageId &&
\s+persistedPageId === this.currentPage.pageId && this.loaded &&
\s+!this.dataLoading && !this.dataLoadFailed`;

assert.match(canvas,
  /const generation: number = this\.pageLoadGeneration;\s+this\.invalidateOriginalInkReservation\(\)/);
assert.match(canvas, /deferred save failed for stale page/);
assert.match(canvas, /current-page flush failed after navigation/);
assert.match(canvas,
  new RegExp(String.raw`if \(${staleContextGuard}\) \{\s+this\.reportSaveFailure\(e\);\s+\}`));
assert.match(canvas,
  new RegExp(String.raw`if \(${persistedStaleContextGuard}\) \{\s+this\.reportSaveFailure\(e\);\s+\}`, 'g'));
assert.equal((canvas.match(/Group committed after page changed/g) || []).length, 1);
assert.equal((canvas.match(/Ungroup committed after page changed/g) || []).length, 1);
assert.match(canvas,
  /if \(generation !== this\.pageLoadGeneration \|\| pageId !== this\.loadedPageId \|\|\s+pageId !== this\.currentPage\.pageId\) \{\s+hilog\.error\([\s\S]{0,220}'Group committed after page changed/);
assert.match(canvas,
  /if \(generation !== this\.pageLoadGeneration \|\| pageId !== this\.loadedPageId \|\|\s+pageId !== this\.currentPage\.pageId\) \{\s+hilog\.error\([\s\S]{0,240}'Ungroup committed after page changed/);
assert.match(canvas, /original Group Paste failed for stale page/);
assert.match(canvas, /ordinary Paste deferred save failed for stale page/);
assert.match(canvas, /selection deferred save failed for stale page/);

assert.match(persistence,
  /local CREATE_GROUP members are not current top-level page units/);
assert.match(persistence,
  /local Ungroup source Group is stale or crosses the current page/);
assert.match(persistence, /original Group history source state is stale/);
assert.match(persistence,
  /original clipboard Paste transaction failed|commit original clipboard Paste failed/);
assert.match(queue, /preserveBoundary: preserveBoundary/);
assert.match(queue, /A failed user action is never replaceable/);
assert.match(undo, /candidate\.action\.pageId !== anchor\.action\.pageId/);
assert.match(canvas, /action\.pageId !== this\.loadedPageId/);

console.log('deferredEditorResultsPageBound=' +
  'original-durable-groups-current-page-ui-state|generation-plus-page-guard|' +
  'save-clear-and-failure-bound|group-ungroup-local-install-bound|paste-feedback-bound|' +
  'storage-order-and-history-page-guards');
