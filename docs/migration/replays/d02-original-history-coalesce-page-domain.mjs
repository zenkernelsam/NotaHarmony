import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = process.env.NOTABILITY_ORIGINAL_ROOT ??
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';

function readRepo(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), 'utf8');
}

function readOriginal(fileName) {
  return fs.readFileSync(path.join(originalRoot, fileName), 'utf8');
}

const TRACK = Object.freeze({ NONE: 0, INSERT_TEXT: 1, REMOVE_TEXT: 2, CREATE_INK: 3 });

function coalesceWindow(track) {
  if (track === TRACK.INSERT_TEXT || track === TRACK.REMOVE_TEXT) return 2000;
  if (track === TRACK.CREATE_INK) return 10;
  return -1;
}

function peekGroup(stack) {
  if (stack.length === 0) return [];
  const result = [stack.at(-1)];
  let anchor = stack.at(-1);
  for (let index = stack.length - 2; index >= 0; index--) {
    const candidate = stack[index];
    const window = coalesceWindow(candidate.track);
    if (candidate.noteId !== anchor.noteId || candidate.pageId !== anchor.pageId ||
      window < 0 || candidate.track !== anchor.track ||
      Math.abs(anchor.time - candidate.time) > window) {
      break;
    }
    result.push(candidate);
    anchor = candidate;
  }
  return result;
}

const vnf = readOriginal('vnf.java');
const qnf = readOriginal('qnf.java');
const pnf = readOriginal('pnf.java');
const tzc = readOriginal('tzc.java');
const fzc = readOriginal('fzc.java');
const manager = readRepo('note/src/main/ets/rendering/UndoRedoManager.ets');
const canvas = readRepo('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const persistence = readRepo('note/src/main/ets/data/StrokePersistence.ets');
const fixture = readRepo('note/src/test/UndoRedoManager.test.ets');

const trackComparisons = vnf.match(/pnfVarB != qnfVar\.b\(\)/g) ?? [];
const pairwiseTimestampComparisons = vnf.match(
  /Long\.compareUnsigned\(jA, jA2\)[\s\S]*?pnfVarB\.a\(\)/g) ?? [];

const checks = [
  ['original undo and redo both use adjacent track/time grouping',
    trackComparisons.length >= 2 && pairwiseTimestampComparisons.length >= 2],
  ['original aggregate reverses undo operations and preserves redo order',
    vnf.includes('k1c k1cVar = new k1c(list)') &&
      vnf.includes('au1.O0(arrayList, ((qnf) i1cVar.next()).e())') &&
      vnf.includes('Iterator it2 = list.iterator()') &&
      vnf.includes('au1.O0(arrayList2, ((qnf) it2.next()).d())')],
  ['original action metadata contains track timestamp and extras but no page identity',
    qnf.includes('public final pnf c;') && qnf.includes('public final long d;') &&
      qnf.includes('public final Map e;') && !qnf.includes('pageId')],
  ['original text tracks use two-second windows',
    pnf.includes('new pnf("INSERT_TEXT", 0, ijg.r0(2, dr3Var))') &&
      pnf.includes('new pnf("REMOVE_TEXT", 1, ijg.r0(2, dr3Var))')],
  ['original create-ink track uses a ten-millisecond window',
    pnf.includes('new pnf("CREATE_INK", 2, ijg.r0(10, dr3.MILLISECONDS))')],
  ['original session owns histories by editor owner rather than page identity',
    tzc.includes('public final LinkedHashMap R;') && fzc.includes('tzcVar.R') &&
      fzc.includes('linkedHashMap.get(eofVar)') && fzc.includes('vnfVar = new vnf()')],
  ['Harmony bounds coalescing by adjacent note identity',
    manager.includes('candidate.action.noteId !== anchor.action.noteId')],
  ['Harmony bounds coalescing by adjacent page identity',
    manager.includes('candidate.action.pageId !== anchor.action.pageId')],
  ['Harmony retains pairwise anchor advancement and original time windows',
    manager.includes('anchor = candidate') && manager.includes('INSERT_TEXT_COALESCE_MS') &&
      manager.includes('REMOVE_TEXT_COALESCE_MS') && manager.includes('CREATE_INK_COALESCE_MS')],
  ['editor refuses a multi-action group that violates page or type domain',
    canvas.includes('if (group.length > 1)') &&
      canvas.includes('if (!this.isSinglePageElementGroup(group))') &&
      canvas.includes('refusing a partial move')],
  ['same-page group durable apply remains one database transaction',
    persistence.includes('private async writeHistoryGroupLocked') &&
      persistence.includes('await store.beginTransaction()') &&
      persistence.includes('await store.commit()') && persistence.includes('await store.rollBack()')],
  ['ArkTS fixture covers page and note boundaries in both move directions',
    fixture.includes('bounds coalescing by concrete note and page identity') &&
      fixture.includes('const pageRedoGroup = manager.peekRedoGroup()') &&
      fixture.includes("makeAction('page-1', 'note-2')")],
];

const samePagePairwise = peekGroup([
  { id: 'a', noteId: 'note', pageId: 'page-1', track: TRACK.CREATE_INK, time: 100 },
  { id: 'b', noteId: 'note', pageId: 'page-1', track: TRACK.CREATE_INK, time: 110 },
  { id: 'c', noteId: 'note', pageId: 'page-1', track: TRACK.CREATE_INK, time: 120 },
]);
assert.deepEqual(samePagePairwise.map(entry => entry.id), ['c', 'b', 'a']);

const pageBoundary = peekGroup([
  { id: 'a', noteId: 'note', pageId: 'page-1', track: TRACK.CREATE_INK, time: 100 },
  { id: 'b', noteId: 'note', pageId: 'page-2', track: TRACK.CREATE_INK, time: 105 },
  { id: 'c', noteId: 'note', pageId: 'page-2', track: TRACK.CREATE_INK, time: 110 },
]);
assert.deepEqual(pageBoundary.map(entry => entry.id), ['c', 'b']);

const noteBoundary = peekGroup([
  { id: 'a', noteId: 'note-1', pageId: 'page', track: TRACK.INSERT_TEXT, time: 100 },
  { id: 'b', noteId: 'note-2', pageId: 'page', track: TRACK.INSERT_TEXT, time: 500 },
  { id: 'c', noteId: 'note-2', pageId: 'page', track: TRACK.INSERT_TEXT, time: 900 },
]);
assert.deepEqual(noteBoundary.map(entry => entry.id), ['c', 'b']);

const adjacentGap = peekGroup([
  { id: 'a', noteId: 'note', pageId: 'page', track: TRACK.CREATE_INK, time: 100 },
  { id: 'b', noteId: 'note', pageId: 'page', track: TRACK.CREATE_INK, time: 111 },
  { id: 'c', noteId: 'note', pageId: 'page', track: TRACK.CREATE_INK, time: 120 },
]);
assert.deepEqual(adjacentGap.map(entry => entry.id), ['c', 'b']);

for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`D02_ORIGINAL_HISTORY_COALESCE_PAGE_DOMAIN_REPLAY_OK TOTAL=${checks.length + 4} FAILED=0`);
