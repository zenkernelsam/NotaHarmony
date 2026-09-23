// Phase 636 — 页面级剪切/拷贝/粘贴（Page Cut / Copy / Paste）：原版内容
// 管理器 n9j 单页菜单顺序为 Add Page、Cut、Copy、Paste、Duplicate、
// Rotate Page、Create Template、Clear Page（n9j.java ~1968-2083）。
// 派发链（de2.java:193-230）：
//   * Copy  = de2.o(list) -> new ae2(this, list, ef2Var, 2)
//   * Cut   = de2.p(list) -> new ae2(this, list, ef2Var, 3)
//   ae2 case 2：u5j.e(x09, list) 序列化页负载（wz9.u 有效 nz9 +
//     l7j.c 单页 PDF 折叠 + oz9 bookmark）后写进程级页剪贴板
//     mg2Var.b = new dg2(list.size(), arrayListE)（dg2 = CopiedPagesData
//     { ops, pageCount }），再 asdVar.k(null, TRUE) 通知 UI；
//   ae2 case 3：同样的序列化 + 剪贴板写入后，de2.i(de2Var, x09Var3, list)
//     构造删除 ops 并 x82.I(m1dVar3, th7VarI, ...) 应用——即 Cut 的持久
//     记录与 Delete Pages 相同；
//   Paste：n9j 菜单项仅在 mg2.b != null（de2.java:54 bsd.a(...)）时出现，
//     经 lg2/m1d.c0 把剪贴板 op 流转码应用到插入锚点。
// Harmony 对齐：
//   * rendering/OriginalPageClipboard.ets = 进程级页剪贴板（CopiedPagePayload
//     = 有效 nz9 + bookmark + PageCopyPlan），拷贝时深冻结快照；
//   * NoteCanvasView.captureCurrentPageCopyPlan 生成元素+页内组图副本计划
//     （originalGroupGraphForPageCopy），与 Duplicate 同源；
//   * Cut = copyCurrentPage + 既有 deleteCurrentPage（DELETE_PAGE 行动）；
//   * Paste = PageRepositoryImpl.insertCopiedPage（锚点后 CreatePage，
//     DUPLICATE_PAGE 伴随 op ——与 Duplicate 同型日志，恰如原版两条手势
//     产出同一 op 流）+ commitCopiedPageContent 转码写入；
//   * PageManagerBar 菜单顺序对齐原版，Paste 仅剪贴板非空时出现；
//   * 跨笔记粘贴仅允许无图片页（图片资产行为按笔记链接，fail-closed 差异
//     见 ADR-0603）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const n9j = fs.readFileSync(`${originalRoot}n9j.java`, 'utf8');
const de2 = fs.readFileSync(`${originalRoot}de2.java`, 'utf8');
const ae2 = fs.readFileSync(`${originalRoot}ae2.java`, 'utf8');
const mg2 = fs.readFileSync(`${originalRoot}mg2.java`, 'utf8');
const dg2 = fs.readFileSync(`${originalRoot}dg2.java`, 'utf8');

const pageClipboard = fs.readFileSync('note/src/main/ets/rendering/OriginalPageClipboard.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const repo = fs.readFileSync('note/src/main/ets/data/PageRepositoryImpl.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const repoIf = fs.readFileSync('note/src/main/ets/data/RepositoryInterfaces.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const undoRedo = fs.readFileSync('note/src/main/ets/rendering/UndoRedoManager.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const notePage = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const pageBar = fs.readFileSync('note/src/main/ets/ui/editor/PageManagerBar.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const stringsBase = fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const stringsZh = fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}

// --- 原版证据：菜单项、派发与页剪贴板 ---
check(n9j.includes('R.string.feature_note__content_manager_cut'),
  'original menu exposes feature_note__content_manager_cut');
check(n9j.includes('R.string.feature_note__content_manager_copy'),
  'original menu exposes feature_note__content_manager_copy');
check(n9j.includes('R.string.feature_note__content_manager_paste'),
  'original menu exposes feature_note__content_manager_paste');
check(n9j.indexOf('content_manager_cut') < n9j.indexOf('content_manager_copy') &&
  n9j.indexOf('content_manager_copy') < n9j.indexOf('content_manager_paste') &&
  n9j.indexOf('content_manager_paste') < n9j.indexOf('content_manager_duplicate'),
  'original single-page menu orders Cut < Copy < Paste < Duplicate');
check(de2.includes('public final void o(List list)') &&
  de2.includes('new ae2(this, list, ef2Var, 2)'),
  'de2.o launches ae2 coroutine variant 2 (Copy)');
check(de2.includes('public final void p(List list)') &&
  de2.includes('new ae2(this, list, ef2Var, 3)'),
  'de2.p launches ae2 coroutine variant 3 (Cut)');
check(de2.includes('"Copy pages with empty page selection"') &&
  de2.includes('"Cut pages with empty page selection"'),
  'copy/cut log-and-return on empty selection');
check(ae2.includes('ArrayList arrayListE = u5j.e((x09) k1aVar3.J, list)'),
  'ae2 case 2 serializes the page payload via u5j.e');
check(ae2.includes('mg2Var.b = dg2Var'),
  'ae2 case 2 stores the stream into the page clipboard mg2.b');
check(dg2.includes('CopiedPagesData(ops='),
  'dg2 is the CopiedPagesData { ops, pageCount } record');
check(mg2.includes('public dg2 b'),
  'mg2.b is the process-scoped page clipboard slot');
check(ae2.includes('ArrayList arrayListE2 = u5j.e(x09Var3, list)') &&
  ae2.includes('mg2Var2.b = dg2Var2'),
  'ae2 case 3 (Cut) stores the same payload before deleting');
check(ae2.includes('th7 th7VarI = de2.i(de2Var, x09Var3, list)') &&
  ae2.includes('x82.I(m1dVar3, th7VarI, dofVar3'),
  'ae2 case 3 applies the same de2.i delete ops as Delete Pages');
check(de2.includes('mg2Var.b != null'),
  'original gates the Paste item on a non-empty page clipboard');

// --- Harmony：进程级页剪贴板 ---
check(pageClipboard.includes('export interface CopiedPagePayload'),
  'CopiedPagePayload models the clipboard record');
check(pageClipboard.includes('noteId: string') &&
  pageClipboard.includes('sourcePageId: string') &&
  pageClipboard.includes('background: PageBackground | null') &&
  pageClipboard.includes('bookmarked: boolean') &&
  pageClipboard.includes('plan: PageCopyPlan'),
  'CopiedPagePayload carries note/source/background/bookmark/plan');
check(pageClipboard.includes('export function storeCopiedPage') &&
  pageClipboard.includes('export function copiedPagePayload') &&
  pageClipboard.includes('export function hasCopiedPage') &&
  pageClipboard.includes('export function clearCopiedPage'),
  'page clipboard exposes store/read/has/clear accessors');
check(pageClipboard.includes('let copiedPage: CopiedPagePayload | null = null'),
  'page clipboard is an in-memory process-scoped record');

// --- Harmony：桥接层 ---
check(undoRedo.includes('export interface PageCopyPlan extends PageContentSnapshot') &&
  undoRedo.includes('groups: OriginalSelectionGroup[]') &&
  undoRedo.includes('topGroupIds: string[]'),
  'PageCopyPlan extends the page snapshot with the group subgraph');
check(undoRedo.includes('captureCurrentPageCopyPlan: () => PageCopyPlan'),
  'EditorHistoryBridge exposes captureCurrentPageCopyPlan');
check(undoRedo.includes('commitCopiedPageContent: (pageId: string, plan: PageCopyPlan'),
  'EditorHistoryBridge exposes commitCopiedPageContent');
check(canvas.includes('captureCurrentPageCopyPlan: (): PageCopyPlan => this.currentPageCopyPlan('),
  'canvas wires the copy-plan capture');
check(canvas.includes('commitCopiedPageContent: async (pageId: string, plan: PageCopyPlan'),
  'canvas wires the stored-plan commit');
check(canvas.includes('private currentPageCopyPlan(snapshot: PageContentSnapshot): PageCopyPlan') &&
  canvas.includes('originalGroupGraphForPageCopy(this.selectionGroups, leafIds)'),
  'copy plan reuses the page-local group subgraph builder');
check(canvas.includes('function pageCopyPlanToPastePlan(plan: PageCopyPlan): OriginalClipboardPastePlan'),
  'canvas re-wraps the plan at the persistence boundary (no structural typing)');
check(canvas.includes('this.persistence.commitOriginalDuplicatePageContent(\n      this.noteId, pageId, pageCopyPlanToPastePlan(plan), history)'),
  'stored plan replays through the duplicate-page transcode');

// --- Harmony：仓储层 ---
check(repo.includes('async insertCopiedPage(noteId: string, anchorPageId: string,\n    background: PageBackground | null, bookmarked: boolean,'),
  'insertCopiedPage takes the clipboard metadata instead of a live source');
check(repo.includes('private async insertPageAfterAnchor(store: relationalStore.RdbStore'),
  'duplicate/paste share the anchored insert body');
check(repo.includes('await persistOriginalDuplicatePage(store, noteId, anchorPageId, background,'),
  'insert writes the anchored CreatePage with the stored background');
check(repo.includes('opType: OpType.DUPLICATE_PAGE') &&
  repo.indexOf('insertPageAfterAnchor') < repo.indexOf('async restoreDuplicatedPage'),
  'paste journals the same DUPLICATE_PAGE companion');
check(repoIf.includes('insertCopiedPage(noteId: string, anchorPageId: string'),
  'PageRepository interface declares insertCopiedPage');

// --- Harmony：NotePage 动作 ---
check(notePage.includes('private async copyCurrentPage(): Promise<void>') &&
  notePage.includes('historyBridge.captureCurrentPageCopyPlan()') &&
  notePage.includes('duplicatedOriginalPageBackground(source)') &&
  notePage.includes('storeCopiedPage(payload)'),
  'copyCurrentPage serializes the page into the clipboard');
check(notePage.includes('private async cutCurrentPage(): Promise<void>') &&
  notePage.includes('await this.copyCurrentPage()') &&
  notePage.includes('await this.deleteCurrentPage()'),
  'cutCurrentPage = copy + existing DELETE_PAGE flow (ae2 case 3 parity)');
check(notePage.includes('private async pasteCopiedPage(): Promise<void>') &&
  notePage.includes('const payload: CopiedPagePayload | null = copiedPagePayload()'),
  'pasteCopiedPage reads the page clipboard');
check(notePage.includes('await this.pageRepo.insertCopiedPage(\n      this.noteId, anchorPageId, payload.background, payload.bookmarked, history)'),
  'paste inserts the copied page after the current anchor');
check(notePage.includes('await historyBridge.commitCopiedPageContent(pasted.pageId, payload.plan, history)'),
  'paste commits the stored plan through the transcode');
check(notePage.includes("type: UndoableActionType.DUPLICATE_PAGE") &&
  notePage.indexOf('private async pasteCopiedPage') > notePage.indexOf('private async copyCurrentPage'),
  'paste reuses the DUPLICATE_PAGE action (identical durable journal)');
check(notePage.includes('payload.noteId !== this.noteId && payload.plan.images.length > 0'),
  'image-bearing pages fail closed across notes (asset linkage)');
check(notePage.includes('payload.noteId === this.noteId || payload.plan.images.length === 0'),
  'canPasteCopiedPage allows image-free cross-note paste');
check(notePage.includes('this.pageClipboardVersion++'),
  'copy bumps the clipboard version to refresh the menu gate');

// --- Harmony：菜单与资源 ---
check(pageBar.includes('onCutPage: () => void') &&
  pageBar.includes('onCopyPage: () => void') &&
  pageBar.includes('onPastePage: () => void') &&
  pageBar.includes('canPastePage: boolean = false'),
  'PageManagerBar exposes cut/copy/paste callbacks and the paste gate');
check(pageBar.indexOf("app.string.cut_page") < pageBar.indexOf("app.string.copy_page") &&
  pageBar.indexOf("app.string.copy_page") < pageBar.indexOf("app.string.duplicate_page"),
  'menu orders Cut < Copy before Duplicate (original order)');
check(pageBar.includes('if (this.canPastePage)') &&
  pageBar.includes("app.string.paste_page"),
  'Paste item renders only while the clipboard is non-empty');
check(notePage.includes('canPastePage: this.pageClipboardVersion >= 0 && this.canPasteCopiedPage()'),
  'NotePage passes the clipboard gate to the bar');
check(notePage.includes('this.cutCurrentPage()') &&
  notePage.includes('this.copyCurrentPage()') &&
  notePage.includes('this.pasteCopiedPage()'),
  'NotePage wires the three callbacks through runPageOperation');
check(stringsBase.includes('"cut_page"') && stringsBase.includes('"Copy"') &&
  stringsBase.includes('"paste_page"'),
  'base resources carry cut/copy/paste labels');
check(stringsZh.includes('剪切') && stringsZh.includes('拷贝') && stringsZh.includes('粘贴'),
  'zh_CN resources carry localized cut/copy/paste labels');
check(stringsBase.includes('"paste_page_unsupported"'),
  'base resources carry the cross-note image gate message');

console.log(`D04_ORIGINAL_PAGE_CUT_COPY_PASTE_REPLAY_OK TOTAL=${total} FAILED=0`);
