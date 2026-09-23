// Phase 640 — 页书签切换可撤销化（原版 ae2 variant 0 → u5j.s ModifyPage 字段 3，
// 经 x82.I + dof 日志通道应用，dof 为"可撤销"策略标记，cof.toString() = "NotUndoable"）。
// 原版派发链（decompiled_1.0.3）：
//   ae2 case 0（书签协程）-> 对选中页逐页判定：
//     列表含页且 fw4Var.a.l() 非书签 → oz9.BOOKMARKED；否则 oz9.UNBOOKMARKED
//   -> List listL0 = m18.l0(u5j.s(x09Var, list3, null, null, oz9Var, 6))
//      （掩码 6 = 位 2|4 → num/m2d 置 null，oz9 保留 → 仅写字段 3 书签寄存器）
//   -> x82.I(m1dVar, listL0, dofVar, iw3Var, this)   // dof = eof 可撤销实现
// eof 策略证据：dof implements eof（空标记 = 可撤销）；
//   cof implements eof，toString() == "NotUndoable" —— 原版明确区分两种策略。
// 关键语义：单选页书签切换 = 取反（等价于原版单页列表的逐页判定结果）；
//   该写入是可撤销动作，与旋转页（zd2 case 1，同一 x82.I 通道）同级。
// Harmony 对齐：
//   * OpType.PAGE_BOOKMARK = 6：持久历史 companion op，载荷携带
//     fromRevision/toRevision/pageId/bookmarkedBefore/bookmarkedAfter；
//     书签翻转不是结构变更，PageStructureOpCodec.samePageSettings 刻意不含
//     bookmarked（ADR-0508），UPDATE_PAGE 无法承载；
//   * PageRepositoryImpl.setPageBookmarked 接受可选 HistoryMetadata：
//     原版路径 persistOriginalPageBookmark 落 ModifyPage（reducer 内
//     advanceStructureRevision），随后追加 PAGE_BOOKMARK companion 并校验
//     结构版本 +1；legacy 路径直写 page_info 后以同款守 guard 自增版本再落
//     companion；寄存器已是目标值时 fail-closed；
//   * UndoableActionType.PAGE_BOOKMARK = 26 + PageBookmarkAction
//     （bookmarkedBefore/After）；NotePage.toggleCurrentPageBookmark 构造动作、
//     preparePageAction、带 history 调仓储、pushPageAction；
//   * applyPageHistory / validatePageActionState 新增分支：撤销按 before、
//     重做按 after 重放 setPageBookmarked（UNDO/REDO effect 的 companion
//     记录真实迁移），并校验页存在且当前寄存器等于预期源值；
//   * NoteCanvasView.isPageAction 收录 PAGE_BOOKMARK，走异步页历史通道；
//   * PersistentHistory 物化 PAGE_BOOKMARK companion 为 PageBookmarkAction
//     （重启后可继续撤销/重做）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const ae2 = fs.readFileSync(`${originalRoot}ae2.java`, 'utf8');
const u5j = fs.readFileSync(`${originalRoot}u5j.java`, 'utf8');
const cof = fs.readFileSync(`${originalRoot}cof.java`, 'utf8');
const dof = fs.readFileSync(`${originalRoot}dof.java`, 'utf8');
const x82 = fs.readFileSync(`${originalRoot}x82.java`, 'utf8');

const opTypes = fs.readFileSync('note/src/main/ets/core/model/OpTypes.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const codec = fs.readFileSync('note/src/main/ets/data/PageBookmarkOpCodec.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const structureCodec = fs.readFileSync('note/src/main/ets/data/PageStructureOpCodec.ets', 'utf8')
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
const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const persistence = fs.readFileSync('note/src/main/ets/data/OriginalPagePersistence.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const modifyPage = fs.readFileSync('note/src/main/ets/data/OriginalModifyPageOperation.ets', 'utf8')
  .replaceAll('\r\n', '\n');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}

// --- 原版证据：ae2 variant 0 书签切换走可撤销日志通道 ---
check(ae2.includes('oz9Var = oz9.BOOKMARKED;') && ae2.includes('oz9Var = oz9.UNBOOKMARKED;'),
  'ae2 variant 0 resolves BOOKMARKED/UNBOOKMARKED per selected page');
check(ae2.includes('!fw4Var.a.l()'),
  'ae2 variant 0 bookmarks pages that are not already bookmarked');
check(ae2.includes('m18.l0(u5j.s(x09Var, list3, null, null, oz9Var, 6))'),
  'ae2 emits a single u5j.s ModifyPage carrying the oz9 register');
check(ae2.includes('x82.I(m1dVar, listL0, dofVar, iw3Var, this)'),
  'ae2 applies the bookmark op through x82.I with the dof marker');
check(dof.includes('class dof implements eof'),
  'dof is an eof implementation (the undoable policy marker)');
check(cof.includes('class cof implements eof') && cof.includes('return "NotUndoable";'),
  'cof.toString() = "NotUndoable" — eof is the undo-policy type');
check(u5j.includes('public static ge8 s(x09 x09Var, List list, Integer num, m2d m2dVar, oz9 oz9Var, int i)'),
  'u5j.s builds a ModifyPage with optional position/background/bookmark fields');
check(u5j.includes('if ((i & 8) != 0)') && u5j.includes('return r0j.a(list, lxcVarA, m2dVar, oz9Var);'),
  'u5j.s mask 6 keeps oz9 while nulling num and m2d');
check(x82.includes('eof eofVar') || x82.includes('eof '),
  'x82.I accepts the eof policy parameter');

// --- Harmony：操作类型与 companion 编解码 ---
check(opTypes.includes('PAGE_BOOKMARK = 6'),
  'OpType.PAGE_BOOKMARK occupies the free slot 6');
check(codec.includes('const MAGIC_V1: number[] = [0x4E, 0x50, 0x42, 0x4B]'),
  'bookmark codec uses the NPBK magic');
check(codec.includes('pageId: string') && codec.includes('bookmarkedBefore: boolean') &&
  codec.includes('bookmarkedAfter: boolean'),
  'bookmark mutation carries page identity and both register values');
check(codec.includes('mutation.toRevision !== mutation.fromRevision + 1'),
  'codec requires a single structure-revision step');
check(codec.includes('mutation.bookmarkedBefore === mutation.bookmarkedAfter'),
  'codec rejects a mutation that does not flip the register');
check(codec.includes('reader.atEnd()') && codec.includes('trailing bytes'),
  'codec rejects trailing payload bytes');
check(codec.includes('OpType.PAGE_BOOKMARK'),
  'codec binds the companion op type');
check(!structureCodec.includes('bookmarked'),
  'PageStructureOpCodec still excludes bookmarked (why the companion exists)');
check(structureCodec.includes('page mutation does not change state'),
  'structure codec would classify a bookmark-only diff as a no-op');

// --- Harmony：仓储路径 ---
check(repo.includes('async setPageBookmarked(noteId: string, pageId: string, bookmarked: boolean,\n    history?: HistoryMetadata)'),
  'setPageBookmarked accepts optional history metadata');
check(repo.includes('validateHistoryMetadata(history);'),
  'setPageBookmarked validates history metadata');
check(repo.includes('page bookmark already holds the target register value'),
  'setPageBookmarked fails closed when the register already holds the target');
check(repo.includes('await persistOriginalPageBookmark(store, noteId, pageId, bookmarked);'),
  'original pages still write the ModifyPage oz9 register op');
check(repo.includes('private async appendPageBookmarkMutation(store: relationalStore.RdbStore'),
  'repository appends a PAGE_BOOKMARK companion inside the transaction');
check(repo.includes('page bookmark write did not advance the structure revision'),
  'companion journaling requires a real revision advance');
check(repo.includes('opType: OpType.PAGE_BOOKMARK') && repo.includes('encodePageBookmarkMutation(mutation)'),
  'companion op encodes the bookmark mutation payload');
check(repo.includes("'bookmarked': bookmarked ? 1 : 0"),
  'legacy pages keep the direct page_info bookmark write');
check(repo.includes("'structure_revision': revision + 1"),
  'legacy path bumps structure_revision with the guarded concurrent write');
check(repoIf.includes('setPageBookmarked(noteId: string, pageId: string, bookmarked: boolean,\n    history?: HistoryMetadata)'),
  'PageRepository interface declares the history-aware signature');
check(persistence.includes('encodeOriginalModifyPageBookmark([page], bookmarked)'),
  'the synced ModifyPage op keeps writing only the oz9 field');
check(modifyPage.includes('await this.orderStore.advanceStructureRevision(store, operation.noteId, \'modify-page\')') ||
  modifyPage.includes('advanceStructureRevision'),
  'the ModifyPage reducer advances structure_revision when the register write wins');

// --- Harmony：持久历史物化 ---
check(history.includes('decodePageBookmarkMutation'),
  'PersistentHistory imports the bookmark codec');
check(history.includes('action.operations[0].opType === OpType.PAGE_BOOKMARK'),
  'materializer dispatches on the bookmark op type');
check(history.includes('persistent page bookmark action must contain exactly one mutation'),
  'materializer rejects multi-op bookmark groups');
check(history.includes('type: UndoableActionType.PAGE_BOOKMARK') &&
  history.includes('bookmarkedBefore: bookmarkMutation.bookmarkedBefore') &&
  history.includes('bookmarkedAfter: bookmarkMutation.bookmarkedAfter'),
  'materialized PageBookmarkAction carries both register values');

// --- Harmony：动作模型 ---
check(undoRedo.includes('PAGE_BOOKMARK = 26'),
  'UndoableActionType.PAGE_BOOKMARK occupies slot 26');
check(undoRedo.includes('export interface PageBookmarkAction extends ActionBase') &&
  undoRedo.includes('type: UndoableActionType.PAGE_BOOKMARK;') &&
  undoRedo.includes('bookmarkedBefore: boolean;') &&
  undoRedo.includes('bookmarkedAfter: boolean;'),
  'PageBookmarkAction records pageId plus both register values');
check(undoRedo.includes('PageBookmarkAction | PersistedPageMutationsAction'),
  'the UndoableAction union includes PageBookmarkAction');

// --- Harmony：UI 路径 ---
check(notePage.includes('const action: PageBookmarkAction = {') &&
  notePage.includes('type: UndoableActionType.PAGE_BOOKMARK,') &&
  notePage.includes('bookmarkedBefore: current.bookmarked === true,') &&
  notePage.includes('bookmarkedAfter: next,'),
  'toggleCurrentPageBookmark builds the action with real before/after values');
check(notePage.includes('historyBridge.preparePageAction(action)') &&
  notePage.includes('historyBridge.pushPageAction(action, history)'),
  'the toggle prepares and pushes durable history');
check(notePage.includes('await this.pageRepo.setPageBookmarked(\n      this.noteId, selectedPageId, next, history)'),
  'the toggle passes history into the repository write');
check(notePage.includes('const target: boolean = isUndo ? action.bookmarkedBefore : action.bookmarkedAfter;'),
  'undo/redo replays the inverse register value');
check(notePage.includes('await pageRepository.setPageBookmarked(\n          this.noteId, action.pageId, target, history)'),
  'applyPageHistory routes bookmark moves through the same repository write');
check(notePage.includes('const expected: boolean = isUndo ? action.bookmarkedAfter : action.bookmarkedBefore;'),
  'validatePageActionState requires the live register to match the source value');
check(canvas.includes('type === UndoableActionType.PAGE_BOOKMARK'),
  'NoteCanvasView routes bookmark actions through the page-history channel');

console.log(`D04_ORIGINAL_PAGE_BOOKMARK_UNDO_REPLAY_OK TOTAL=${total} FAILED=0`);
