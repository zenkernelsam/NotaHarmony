// Phase 651 — 批操作一步撤销（PAGE_BATCH 跨页归并）。
// 原版证据（decompiled_1.0.3）：
//   ae2.java 每个变体先把全部选中页的 op 汇总为一张 list（m18.l0(u5j.…)），
//   再对整表只调一次 x82.I(m1d, list, dof, iw3, this)；x82.I 把 list 包成
//   wq9 项后以单个 pq1(12, list) 交给 m1dVar.v0 —— 一次应用 = 一条历史。
// Harmony 对齐：dispatchPageSelectionAction 的批派发包在
//   beginPageBatch/endPageBatch 窗口内；窗口内 push 的历史条目打
//   PAGE_BATCH 轨 + 共享 actionTime（单调递增的批次标识）；
//   peekGroup 按 noteId+PAGE_BATCH+actionTime 跨页归并；
//   performHistory 每次只应用并提交一个子条目，continuePageBatch
//   驱动其余子条目（跨页由 pendingHistoryDirection/resume 衔接），
//   对用户仍是「一次撤销恢复整个批」。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const ae2 = fs.readFileSync(`${originalRoot}sources/defpackage/ae2.java`, 'utf8');
const x82 = fs.readFileSync(`${originalRoot}sources/defpackage/x82.java`, 'utf8');

const opTypes = fs.readFileSync('note/src/main/ets/core/model/OpTypes.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const undoRedo = fs.readFileSync('note/src/main/ets/rendering/UndoRedoManager.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const noteCanvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const notePage = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const persistence = fs.readFileSync('note/src/main/ets/data/StrokePersistence.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const metadata = fs.readFileSync('note/src/main/ets/data/PersistentHistoryMetadata.ets', 'utf8')
  .replaceAll('\r\n', '\n');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}
function section(source, startMarker, endMarker) {
  const start = source.indexOf(startMarker);
  const end = source.indexOf(endMarker, start);
  assert.ok(start !== -1 && end > start, startMarker);
  return source.slice(start, end);
}

// --- 原版证据：一次应用 = 一步撤销 ---
check(ae2.match(/x82\.I\(m1dVar\d?, listL\d/g) !== null,
  'ae2 batch variants hand the whole op list to a single x82.I call');
check((ae2.match(/x82\.I\(/g) ?? []).length <= 5,
  'ae2 issues at most one x82.I apply per batch variant');
check(x82.includes('arrayList.add(new wq9((cee) it.next(), null, false, null, 30))') &&
  x82.includes('new pq1(12, list)') && x82.includes('m1dVar.v0(eofVar, map2, ix4Var'),
  'x82.I wraps the whole op list into one pq1 batch → one m1d.v0 apply = one undo step');

// --- PAGE_BATCH 轨定义与元数据通道 ---
check(opTypes.includes('PAGE_BATCH = 4'),
  'HistoryCoalesceTrack gains the explicit PAGE_BATCH track');
check(metadata.includes('history.coalesceTrack !== HistoryCoalesceTrack.PAGE_BATCH'),
  'persistent history metadata accepts the PAGE_BATCH track');
check(undoRedo.includes('history.coalesceTrack > HistoryCoalesceTrack.PAGE_BATCH'),
  'acceptPreparedHistory bound raised to PAGE_BATCH');

// --- 批窗口：共享 actionTime + 强制轨道 ---
const batch = section(undoRedo, '  beginPageBatch(): void {', '  peekUndo(): UndoableAction | null {');
check(batch.includes('this.pageBatchActionTime = Math.max(Date.now(), this.pageBatchActionTime + 1);'),
  'batch actionTime is monotonic — two batches can never share a group identity');
check(batch.includes('this.pageBatchDepth++') && undoRedo.includes('this.pageBatchDepth--'),
  'begin/end maintain a depth counter for the batch window');
const createMeta = section(undoRedo, 'private createHistoryMetadata(', 'private coalesceTrackFor(');
check(createMeta.includes('this.pageBatchDepth > 0 ? HistoryCoalesceTrack.PAGE_BATCH : this.coalesceTrackFor(action)') &&
  createMeta.includes('this.pageBatchDepth > 0 ? this.pageBatchActionTime : now'),
  'in-window pushes stamp PAGE_BATCH + the shared batch actionTime');
check(undoRedo.includes('Math.max(this.pageBatchActionTime, history.actionTime)'),
  'restored batch entries raise the batch clock so post-restart ids stay unique');

// --- peekGroup 跨页归并 ---
const peek = section(undoRedo, 'private peekGroup(', '  private commitGroup(');
check(peek.includes('anchor.history.coalesceTrack === HistoryCoalesceTrack.PAGE_BATCH') &&
  peek.includes('candidate.history.coalesceTrack !== HistoryCoalesceTrack.PAGE_BATCH') &&
  peek.includes('candidate.history.actionTime !== anchor.history.actionTime'),
  'peekGroup merges PAGE_BATCH entries by noteId+track+shared actionTime, across pages');
check(peek.indexOf('PAGE_BATCH') < peek.indexOf('candidate.action.pageId !== anchor.action.pageId'),
  'the batch branch is evaluated before the page-bound window rule');

// --- 消费端：逐条应用 + 自动续批 ---
check(noteCanvas.includes('beginPageBatch: (): void => this.undoRedo.beginPageBatch()') &&
  noteCanvas.includes('endPageBatch: (): void => this.undoRedo.endPageBatch()'),
  'EditorHistoryBridge exposes the batch window to NotePage');
check(noteCanvas.includes('const pageBatchTime: number = this.isPageActionBatchGroup(group)') &&
  noteCanvas.includes('if (group.length > 1 && pageBatchTime < 0)'),
  'multi-entry batch groups bypass the single-page-element-group guard');
const isBatch = section(noteCanvas, 'private isPageActionBatchGroup(', 'private continuePageBatch(');
check(isBatch.includes('group[0].history.coalesceTrack !== HistoryCoalesceTrack.PAGE_BATCH') &&
  isBatch.includes('move.history.actionTime !== actionTime'),
  'isPageActionBatchGroup pins same-note PAGE_BATCH entries sharing one actionTime');
const cont = section(noteCanvas, 'private continuePageBatch(', 'private isSinglePageElementGroup(');
check(cont.includes('this.undoRedo.peekUndoGroup()') && cont.includes('this.undoRedo.peekRedoGroup()') &&
  cont.includes('next[0].history.actionTime !== batchTime') && cont.includes('this.performHistory(isUndo)'),
  'continuePageBatch re-enters performHistory while same-batch entries remain');
check(noteCanvas.match(/this\.commitHistory\(action, isUndo\);\s*\n\s*this\.continuePageBatch\(pageBatchTime, isUndo\);/) !== null,
  'the generic apply path continues the batch after committing one child');
check(noteCanvas.match(/if \(committed\) \{\s*\n\s*this\.continuePageBatch\(pageBatchTime, isUndo\);\s*\n\s*\}/) !== null,
  'the page-action path continues the batch only after historyBusy releases');

// --- 派发包窗 ---
const dispatch = section(notePage, 'private dispatchPageSelectionAction(', 'applyNoteBackgroundSettings');
check(dispatch.includes("this.historyBridge?.beginPageBatch();") &&
  dispatch.match(/finally \{\s*\n\s*this\.historyBridge\?\.endPageBatch\(\);\s*\n\s*\}/) !== null,
  'batch dispatch wraps all child ops in a begin/end window with finally');
check(dispatch.indexOf('beginPageBatch') < dispatch.indexOf("case 'copy'"),
  'the batch window opens before any child op runs');

// --- 持久化闸口：仅批可达写入放宽 ---
const clearGate = section(persistence, 'async clearOriginalPageContent(', 'async commitOriginalHandwritingConversion(');
check(clearGate.includes('history.coalesceTrack !== HistoryCoalesceTrack.PAGE_BATCH'),
  'clearOriginalPageContent accepts the batch PUSH track');
const dupGate = section(persistence, 'async commitOriginalDuplicatePageContent(', 'async applyOriginalClipboardPasteHistory(');
check(dupGate.includes('history.coalesceTrack !== HistoryCoalesceTrack.PAGE_BATCH'),
  'commitOriginalDuplicatePageContent accepts the batch PUSH track');
check((persistence.match(/coalesceTrack !== HistoryCoalesceTrack\.PAGE_BATCH/g) ?? []).length === 2,
  'only the two batch-reachable writers relaxed their non-coalesced gate');

// --- 既有语义保持 ---
check(undoRedo.includes('candidate.action.pageId !== anchor.action.pageId') &&
  undoRedo.includes('Math.abs(anchor.history.actionTime - candidate.history.actionTime) > window'),
  'non-batch tracks still group by same-page + time window only');
check(undoRedo.includes('if (track === HistoryCoalesceTrack.CREATE_INK)') &&
  undoRedo.includes('return -1;'),
  'PAGE_BATCH keeps a negative coalesce window — never merges by time');

console.log(`D05_ORIGINAL_PAGE_BATCH_HISTORY_REPLAY_OK TOTAL=${total} FAILED=0`);
