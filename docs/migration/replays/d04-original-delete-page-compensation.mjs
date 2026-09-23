// Phase 638 — 末页删除补偿对齐（原版 de2.i：删除后剩余 < 2 时同一 op 流补插空白页）。
// 原版派发链（decompiled_1.0.3）：
//   ae2 case 4（删除页协程）-> de2.i(de2Var, x09Var, list)
//   -> th7VarS.add(u5j.l(x09Var, arrayList, list, 10))   // 先写删页 op
//   -> if (list2.size() - list.size() < 2)
//        th7VarS.add(u5j.i(x09Var, list2.size() - 1, 0, 14)); // 同流补插空白页
//   -> m18.E(th7VarS)  ->  x82.I(m1d, th7, dof, iw3, cont)  // 单事务应用 = 单个撤销单元
// ae2 case 3（Cut）复用同一 de2.i：序列化进 mg2.b 后同样走补偿删除。
// 关键语义：
//   * list2 = x09.i = 笔记当前页表；size() - list.size() < 2 ⇔ 删除后不足两页；
//   * u5j.i 的插入下标 list2.size() - 1 = 末页边界；对单页删除而言
//     [A,B] 删 A → [comp,B]、删 B → [A,comp]、[A] 删 A → [comp] ——
//     补偿页恰好落在受害页槽位；
//   * haj.a(anchor, null, 1, oz9.UNBOOKMARKED, 16)（u5j.i 内）：
//     nz9 = null（继承笔记默认背景）、UNBOOKMARKED、单页；
//   * 删除 + 补偿在同一 th7 op 流中提交 → 原版撤销/重做以该流为最小单元。
// Harmony 对齐：
//   * OpType.DELETE_PAGE_COMPENSATION = 5：持久历史 companion op，载荷携带
//     deletedPageId / insertedPage(PageInfo) / pageOrderBefore/After（双向校验）；
//   * PageRepositoryImpl.deletePageWithCompensation 单事务：checkpoint +
//     隐藏/物理删受害页 + 落点校验后补插空白页（原版路径 persistOriginalPageVisibility
//     + persistOriginalCreatePage 锚定 before[size-2]；legacy 路径
//     physicalDeletePage + insertPageInfoAt，page_index 倒序腾位）；
//   * undoDeletePageWithCompensation / redoDeletePageWithCompensation 镜像往返，
//     各自追加同型 companion（UNDO/REDO effect），失败整体回滚；
//   * PersistentHistory 物化 DELETE_PAGE_COMPENSATION 为带 compensationPage 的
//     DeletePageAction（复用 page_delete_checkpoint 内容）；
//   * NotePage.deleteCurrentPageLocked 在 orderBefore.length <= 2 时走补偿路径；
//     validatePageActionState / applyDeletePageHistory 按同槽位换页校验与应用；
//   * PageManagerBar 移除 pageCount > 1 门（原版删除永不因页数禁用）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const de2 = fs.readFileSync(`${originalRoot}de2.java`, 'utf8');
const ae2 = fs.readFileSync(`${originalRoot}ae2.java`, 'utf8');
const u5j = fs.readFileSync(`${originalRoot}u5j.java`, 'utf8');

const opTypes = fs.readFileSync('note/src/main/ets/core/model/OpTypes.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const codec = fs.readFileSync('note/src/main/ets/data/DeletePageCompensationOpCodec.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const repo = fs.readFileSync('note/src/main/ets/data/PageRepositoryImpl.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const repoIf = fs.readFileSync('note/src/main/ets/data/RepositoryInterfaces.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const history = fs.readFileSync('note/src/main/ets/data/PersistentHistory.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const undoRedo = fs.readFileSync('note/src/main/ets/rendering/UndoRedoManager.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const notePage = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const pageBar = fs.readFileSync('note/src/main/ets/ui/editor/PageManagerBar.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const database = fs.readFileSync('note/src/main/ets/data/DatabaseHelper.ets', 'utf8')
  .replaceAll('\r\n', '\n');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}

// --- 原版证据：de2.i 补偿语义 ---
check(de2.includes('public static final th7 i(de2 de2Var, x09 x09Var, List list)'),
  'de2.i builds the page-delete op stream');
check(de2.includes('th7VarS.add(u5j.l(x09Var, arrayList, list, 10))'),
  'de2.i emits the delete-entities op first');
check(de2.includes('if (list2.size() - list.size() < 2)'),
  'de2.i compensates when the remainder drops below two pages');
check(de2.includes('th7VarS.add(u5j.i(x09Var, list2.size() - 1, 0, 14))'),
  'de2.i appends u5j.i blank-page insert inside the same op stream');
check(de2.includes('List list2 = ((a79) x09Var).i;'),
  'de2.i anchors on x09.i (the note page list)');
check(de2.indexOf('u5j.l(x09Var, arrayList, list, 10)') <
  de2.indexOf('u5j.i(x09Var, list2.size() - 1, 0, 14)'),
  'original emits delete op before the compensation insert');
check(de2.includes('return m18.E(th7VarS);'),
  'de2.i returns a single sealed op stream (one undoable unit)');
check(ae2.includes('th7 th7VarI2 = de2.i(de2Var, (x09) k1aVar5.J, list);'),
  'ae2 plain-delete case routes through de2.i');
check(ae2.includes('x82.I(m1dVar4, th7VarI2, dofVar4, iw3Var, this)'),
  'ae2 applies the delete+compensation stream in one apply');
check(ae2.includes('th7 th7VarI = de2.i(de2Var, x09Var3, list);'),
  'ae2 Cut case reuses the same compensated delete');
check(u5j.includes('UNBOOKMARKED') && u5j.includes('bfj.b('),
  'u5j.i resolves a sequence anchor and emits an unbookmarked blank page');

// --- Harmony：操作类型与编解码 ---
check(opTypes.includes('DELETE_PAGE_COMPENSATION = 5'),
  'OpType.DELETE_PAGE_COMPENSATION occupies the free slot 5');
check(codec.includes('const MAGIC_V1: number[] = [0x44, 0x43, 0x50, 0x31]'),
  'compensation codec uses the DCP1 magic');
check(codec.includes('deletedPageId: string') && codec.includes('insertedPage: PageInfo') &&
  codec.includes('pageOrderBefore: string[]') && codec.includes('pageOrderAfter: string[]'),
  'compensation mutation carries victim id, blank PageInfo, and both orders');
check(codec.includes('const forward: boolean') && codec.includes('const reverse: boolean'),
  'codec validates both PUSH/REDO and UNDO order directions');
check(codec.includes('mutation.deletedPageId === mutation.insertedPage.pageId'),
  'codec rejects identical victim/blank identities');
check(codec.includes('mutation.pageOrderAfter.length !== mutation.pageOrderBefore.length'),
  'codec requires a one-for-one membership swap (page count preserved)');
check(codec.includes('host[mutation.insertedPage.pageIndex] !== mutation.insertedPage.pageId'),
  'codec pins the blank to its materialized slot');
check(codec.includes('reader.atEnd()') && codec.includes('trailing bytes'),
  'codec rejects trailing payload bytes');
check(codec.includes('OpType.DELETE_PAGE_COMPENSATION'),
  'codec binds the companion op type');

// --- Harmony：仓储复合事务 ---
check(repo.includes('async deletePageWithCompensation(noteId: string, pageId: string,'),
  'repository exposes deletePageWithCompensation');
check(repo.includes('async undoDeletePageWithCompensation(noteId: string, actionId: string,') &&
  repo.includes('async redoDeletePageWithCompensation(noteId: string, actionId: string,'),
  'repository exposes undo/redo companions for compensated deletes');
check(repo.includes("history.effect !== HistoryEffect.PUSH"),
  'deletePageWithCompensation requires PUSH history');
check(repo.includes('before.length < 1 || before.length > 2'),
  'compensation fires exactly when the note holds at most two pages');
check(repo.includes('await this.createDeleteCheckpoint(store, noteId, pageId, before, history)'),
  'the victim still gets a full delete checkpoint');
check(repo.includes('before.length - 2') && repo.includes('persistOriginalCreatePage('),
  'original path anchors the blank at before[size-2] so it lands at the victim slot');
check(repo.includes('persistOriginalPageVisibility(store, noteId, pageId, true)') &&
  repo.includes('persistOriginalPageVisibility(store, noteId, pageId, false)') &&
  repo.includes('persistOriginalPageVisibility(store, noteId, victimId, false)') &&
  repo.includes('persistOriginalPageVisibility(store, noteId, compensationPageId, true)'),
  'original path hides/unhides via page-visibility ops in both directions');
check(repo.includes('private async physicalDeletePage(store: relationalStore.RdbStore'),
  'legacy path physically removes the victim row');
check(repo.includes('private async insertPageInfoAt(store: relationalStore.RdbStore'),
  'legacy path inserts the blank at an arbitrary index');
check(repo.includes('for (let i: number = pages.length - 1; i >= 0; i--)'),
  'insertPageInfoAt shifts existing page_index values in descending order');
check(database.includes('CREATE UNIQUE INDEX IF NOT EXISTS idx_page_info_note'),
  'the (note_id, page_index) unique index requires the descending shift');
check(repo.includes('private newCompensationPage(victim: PageInfo): PageInfo') &&
  repo.includes('background: null,') && repo.includes('bookmarked: false'),
  'legacy compensation page borrows dimensions with null background and no bookmark');
check(repo.includes('private async restoreCheckpointedPage(store: relationalStore.RdbStore'),
  'checkpoint restore is factored for reuse by the compound undo');
check(repo.includes('await this.restoreCheckpointedPage(store, noteId, checkpoint, searches, before)') &&
  repo.includes('assertLivePageElementIdsAvailable'),
  'compound undo restores checkpointed page content and guards element identities');
check(repo.includes('private async appendDeletePageCompensationCompanion'),
  'undo/redo write the same companion op type');
check(repo.includes('delete compensation did not land at the victim slot'),
  'the push transaction fail-closed on the blank landing off the victim slot');
check(repo.includes('compensated delete did not advance the structure revision'),
  'companion journaling requires a real revision advance');
check(repo.includes("'a note must retain at least one page'") ||
  repo.includes('a note must retain at least one page'),
  'ordinary delete still refuses to empty a note');
check(repoIf.includes('deletePageWithCompensation(noteId: string, pageId: string,') &&
  repoIf.includes('undoDeletePageWithCompensation(noteId: string, actionId: string,') &&
  repoIf.includes('redoDeletePageWithCompensation(noteId: string, actionId: string,'),
  'PageRepository interface declares all three compensation methods');

// --- Harmony：持久历史物化 ---
check(history.includes("import {\n  decodeDeletePageCompensationMutation, DeletePageCompensationMutation,\n} from './DeletePageCompensationOpCodec';") ||
  history.includes('decodeDeletePageCompensationMutation'),
  'PersistentHistory imports the compensation codec');
check(history.includes('action.operations[0].opType === OpType.DELETE_PAGE_COMPENSATION'),
  'materializer dispatches on the compensation op type');
check(history.includes('compensationPage: mutation.insertedPage'),
  'materialized DeletePageAction carries the compensation page');
check(history.includes('findDeleteCheckpoint(\n      deleteCheckpoints, noteId, action.actionId, mutation.deletedPageId)') ||
  history.includes('mutation.deletedPageId)'),
  'materializer resolves the victim checkpoint for content restoration');
check(history.includes('persistent compensated delete action must contain exactly one mutation'),
  'materializer rejects multi-op compensation groups');
check(history.includes('persistent compensated delete checkpoint contradicts its action'),
  'materializer cross-checks checkpoint creation time against the action');

// --- Harmony：动作模型 ---
check(undoRedo.includes('compensationPage?: PageInfo'),
  'DeletePageAction carries an optional compensation page');

// --- Harmony：UI 路径 ---
check(notePage.includes('const compensated: boolean = orderBefore.length <= 2'),
  'single-page delete compensates when the note holds at most two pages');
check(notePage.includes('this.pages.length === 0') &&
  !notePage.includes('this.pages.length <= 1 || this.historyBridge === null'),
  'deleteCurrentPage no longer refuses the last page');
check(notePage.includes('await pageRepository.deletePageWithCompensation(this.noteId, pageId, history)'),
  'compensated delete routes to the compound repository call');
check(notePage.includes('action.compensationPage = this.clonePage(compensation);') &&
  notePage.includes('action.pageOrderAfter = this.pageIds(updated);') &&
  notePage.includes('action.selectedPageIdAfter = compensation.pageId;'),
  'the pushed action records the real compensation identity, order, and selection');
check(notePage.includes('private async applyDeletePageCompensationHistory(action: DeletePageAction,'),
  'undo/redo dispatch has a dedicated compensated-delete applier');
check(notePage.includes('await pageRepository.undoDeletePageWithCompensation(this.noteId, history.actionId,') &&
  notePage.includes('await pageRepository.redoDeletePageWithCompensation(this.noteId, history.actionId,'),
  'undo/redo call the matching repository companions');
check(notePage.includes('private isDeleteCompensationTransition(source: string[], target: string[],'),
  'validator has a dedicated in-place swap transition check');
check(notePage.includes('this.isDeleteCompensationTransition(sourceOrder, targetOrder, action.pageId,'),
  'validatePageActionState applies the swap check for compensated deletes');
check(notePage.includes('action.compensationPage !== undefined && action.compensationPage !== null'),
  'applyDeletePageHistory dispatches to the compound applier when a blank is recorded');
check(!pageBar.includes('this.pageCount > 1'),
  'PageManagerBar no longer disables Delete at one page');

console.log(`D04_ORIGINAL_DELETE_PAGE_COMPENSATION_REPLAY_OK TOTAL=${total} FAILED=0`);
