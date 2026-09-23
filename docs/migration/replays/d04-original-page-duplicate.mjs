// Phase 635 — 页面复制（Duplicate Page）：原版内容管理器菜单项
// feature_note__content_manager_duplicate 派发 de2.r -> ae2 变体 5。
// ae2 变体 5（de2.java:223-230 new ae2(this, list, ef2Var, 5)）：
//   1) de2.k 取出 (m1d, x09) 引擎对；
//   2) u5j.e(x09, list) 把选中页序列化为 op 流——每页走 wz9.u：
//      * sw9 PDF 寄存器存在时 l7j.c(sw9, cropIndex, pageInAsset) 重建为
//        单页消费，再 m18.O(nz9, sw9VarC, null, null, 29) 只替换 pdf 字段；
//      * 否则直接取 B() 有效 nz9（register ?? note fallback）；
//      * a.b(..., haj.a(null, nz9, 1, (oz9) this.f.K, 16), ..., this.i, ...)
//        携带页 bookmark 与页身份；
//   3) de2.j(de2, x09, list) 逆序遍历文档页表找最后一个选中页 → 插入锚点；
//   4) m1d.c0(x09, ops, anchor, dof, iw3.I, this) 转码应用（全新实体身份）。
// Harmony 对齐：duplicatePage 发 ORIGINAL_CREATE_PAGE（location=源页身份，
// 完整有效 nz9 经 collapsedOriginalPagePdf 折叠）+ DUPLICATE_PAGE 伴随 op
// 持有可持久历史；commitOriginalDuplicatePageContent 复用剪贴板转码机制
// （mappedIds 全新身份、组图自根向下）写实体内容；undo/redo 走
// persistOriginalPageVisibility 隐藏/恢复副本页。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const n9j = fs.readFileSync(`${originalRoot}n9j.java`, 'utf8');
const de2 = fs.readFileSync(`${originalRoot}de2.java`, 'utf8');
const ae2 = fs.readFileSync(`${originalRoot}ae2.java`, 'utf8');
const u5j = fs.readFileSync(`${originalRoot}u5j.java`, 'utf8');
const wz9 = fs.readFileSync(`${originalRoot}wz9.java`, 'utf8');
const l7j = fs.readFileSync(`${originalRoot}l7j.java`, 'utf8');

const opTypes = fs.readFileSync('note/src/main/ets/core/model/OpTypes.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const model = fs.readFileSync('note/src/main/ets/core/model/PageBackgroundModel.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const pagePersistence = fs.readFileSync('note/src/main/ets/data/OriginalPagePersistence.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const createPageEncoder = fs.readFileSync('note/src/main/ets/data/OriginalCreatePagePayloadEncoder.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const duplicateCodec = fs.readFileSync('note/src/main/ets/data/DuplicatePageOpCodec.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const repo = fs.readFileSync('note/src/main/ets/data/PageRepositoryImpl.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const repoIf = fs.readFileSync('note/src/main/ets/data/RepositoryInterfaces.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const strokePersistence = fs.readFileSync('note/src/main/ets/data/StrokePersistence.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const clipboard = fs.readFileSync('note/src/main/ets/rendering/StrokeClipboard.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const undoRedo = fs.readFileSync('note/src/main/ets/rendering/UndoRedoManager.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const persistentHistory = fs.readFileSync('note/src/main/ets/data/PersistentHistory.ets', 'utf8')
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

// --- 原版证据：菜单项与派发链 ---
check(n9j.includes('R.string.feature_note__content_manager_duplicate'),
  'original menu exposes feature_note__content_manager_duplicate');
check(n9j.includes('R.drawable.ui_designsystem__duplicate'),
  'original menu exposes ui_designsystem__duplicate icon');
check(de2.includes('public final void r(List list)'),
  'de2.r is the Duplicate dispatch entry');
check(de2.includes('new ae2(this, list, ef2Var, 5)'),
  'de2.r launches ae2 coroutine variant 5');
check(de2.includes('"Duplicate pages with empty page selection"'),
  'de2.r logs-and-returns on empty selection');
check(ae2.includes('de2.k(de2Var, this)'),
  'ae2 variant 5 resolves the (m1d, x09) engine pair via de2.k');
check(ae2.includes('ArrayList arrayListE3 = u5j.e(x09Var4, list)'),
  'ae2 serializes selected pages via u5j.e');
check(ae2.includes('cxc cxcVarJ = de2.j(de2Var, x09Var4, list)'),
  'ae2 resolves the insertion anchor via de2.j');
check(ae2.includes('m1dVar5.c0(x09Var4, arrayListE3, cxcVarJ, dofVar5'),
  'ae2 applies the transcoded op stream via m1d.c0');
check(u5j.includes('public static ArrayList e(x09 x09Var, Collection collection)'),
  'u5j.e is the page-content serializer');
check(u5j.includes('wz9Var.u(aVar)'),
  'u5j.e serializes each page through wz9.u');
check(wz9.includes('public final qo5 u(a aVar)'),
  'wz9.u is the per-page duplicate payload builder');
check(wz9.includes('sw9 sw9VarC = l7j.c(sw9Var, this.m, ((mmf) this.g.K).I)'),
  'wz9.u collapses PDF metadata through l7j.c');
check(wz9.includes('m18.O(nz9VarB2, sw9VarC, null, null, 29)'),
  'wz9.u replaces only the pdf field of the effective nz9');
check(wz9.includes('nz9VarB = B()'),
  'wz9.u falls back to the effective B() background');
check(wz9.includes('(oz9) this.f.K'),
  'wz9.u carries the page bookmark register');
const haj = fs.readFileSync(`${originalRoot}haj.java`, 'utf8');
check(haj.includes('aVarA.c(3, oz9Var.I, 0)'),
  'haj.a writes the oz9 bookmark into ln2 field 3');
check(l7j.includes('public static'),
  'l7j.c single-page PDF collapse helper exists');
check(de2.includes('ListIterator listIterator = list2.listIterator(list2.size())') &&
  de2.includes('listIterator.hasPrevious()') && de2.includes('listIterator.previous()'),
  'de2.j walks the document page list backwards for the last selected page');
check(de2.includes('public static final cxc j(de2 de2Var, x09 x09Var, List list)'),
  'de2.j returns the anchor page identity');

// --- Harmony：操作类型与伴随 codec ---
check(/DUPLICATE_PAGE = 4,/.test(opTypes),
  'OpType.DUPLICATE_PAGE occupies the free enum slot 4');
check(duplicateCodec.includes('const MAGIC_V1: number[] = [0x4E, 0x44, 0x50, 0x31]'),
  'DuplicatePageOpCodec uses the NDP1 magic');
check(duplicateCodec.includes('export function validateDuplicatePageMutation'),
  'duplicate mutation validator exists');
check(duplicateCodec.includes('duplicate page is not inserted after its source'),
  'validator enforces insert-after-source ordering');
check(duplicateCodec.includes('export function encodeDuplicatePageMutation') &&
  duplicateCodec.includes('export function decodeDuplicatePageMutation'),
  'duplicate mutation encoder/decoder pair exists');
check(persistentHistory.includes('action.operations[0].opType === OpType.DUPLICATE_PAGE'),
  'persistent history materializes DUPLICATE_PAGE actions');
check(persistentHistory.includes('decodeDuplicatePageMutation'),
  'persistent history decodes the duplicate payload');
check(/persistent duplicate page action must contain exactly one mutation/.test(persistentHistory),
  'persistent duplicate materialization requires exactly one companion op');

// --- Harmony：有效背景 + PDF 折叠 ---
check(model.includes('function collapsedOriginalPagePdf(page: PageInfo, pdf: PagePdfBackground)'),
  'shared single-page PDF collapse helper exists');
check(model.includes('export function duplicatedOriginalPageBackground(page: PageInfo)'),
  'duplicatedOriginalPageBackground resolves the effective background');
check(model.includes('duplicated.pdf = collapsedOriginalPagePdf(page, duplicated.pdf)'),
  'duplicate collapses PDF metadata to single-page consumption');
check(model.includes('rotated.pdf = collapsedOriginalPagePdf(page, rotated.pdf)'),
  'rotate shares the same PDF collapse helper');

// --- Harmony：页创建持久化 ---
check(pagePersistence.includes('export async function persistOriginalDuplicatePage'),
  'persistOriginalDuplicatePage exists');
check(pagePersistence.includes(
  'encodeOriginalLocalCreatePage(\n    source, null, null, 1, background, bookmarked)'),
  'duplicate CreatePage anchors at the source identity with the full nz9 and bookmark');
check(createPageEncoder.includes('bookmarked: boolean = false'),
  'CreatePage encoder accepts the bookmark flag');
check(createPageEncoder.includes('bookmarked ? 24 : 0') &&
  createPageEncoder.includes('bytes[rootTable + 24] = 1'),
  'CreatePage encoder writes ln2 field 3 when bookmarked');
check(repo.includes('before[sourceIndex].bookmarked === true'),
  'duplicate propagates the source page bookmark');
check(pagePersistence.includes('OpType.ORIGINAL_CREATE_PAGE'),
  'duplicate page persists as an original CreatePage op');
check(createPageEncoder.includes('background: PageBackground | null = null'),
  'CreatePage encoder accepts a full background override');
check(createPageEncoder.includes('encodeOriginalPageBackgroundTableBlob'),
  'CreatePage encoder serializes the relocatable nz9 blob');

// --- Harmony：仓库事务 ---
check(repo.includes('async duplicatePage(noteId: string, sourcePageId: string'),
  'PageRepositoryImpl.duplicatePage exists');
check(repo.includes('duplicatedOriginalPageBackground(before[sourceIndex])'),
  'duplicate resolves the source page effective background');
check(repo.includes('persistOriginalDuplicatePage(store, noteId, sourcePageId, background,'),
  'duplicate persists the anchored CreatePage');
check(repo.includes('after[sourceIndex + 1].pageId !== mutation.page.pageId'),
  'duplicate asserts the copy lands immediately after its source');
check(repo.includes('opType: OpType.DUPLICATE_PAGE'),
  'duplicate appends the DUPLICATE_PAGE companion op');
check(repo.includes('async restoreDuplicatedPage(noteId: string, pageId: string'),
  'restoreDuplicatedPage exists for redo');
check(repo.includes('persistOriginalPageVisibility(store, noteId, pageId, false)'),
  'duplicate redo restores page visibility');
check(repoIf.includes('duplicatePage(noteId: string, sourcePageId: string'),
  'PageRepository interface exposes duplicatePage');
check(repoIf.includes('restoreDuplicatedPage(noteId: string, pageId: string'),
  'PageRepository interface exposes restoreDuplicatedPage');

// --- Harmony：内容转码 ---
check(strokePersistence.includes('async commitOriginalDuplicatePageContent'),
  'commitOriginalDuplicatePageContent exists');
check(strokePersistence.includes('private async transcodeOriginalPageElements'),
  'the shared element transcode was extracted');
check(strokePersistence.includes('export function validateOriginalDuplicatePageContentPlan'),
  'duplicate content plan validator exists');
check(strokePersistence.includes('validateOriginalElementTranscodePlan(plan, false'),
  'duplicate plan allows an empty group graph (no synthetic wrapper)');
check(strokePersistence.includes('original duplicate target page is not empty'),
  'duplicate content write requires the fresh empty target page');
check(strokePersistence.includes('original clipboard Paste requires non-coalesced PUSH history') &&
  strokePersistence.includes('commit original clipboard Paste failed'),
  'clipboard paste path still validates its own contract');
check(/await this\.transcodeOriginalPageElements\(\s*store, noteId, pageId, page, stablePlan, maximumZIndex\)/.test(strokePersistence),
  'both paste and duplicate share the transcode body');
check(clipboard.includes('export function originalGroupGraphForPageCopy'),
  'whole-page group graph copy helper is exported');
check(clipboard.includes('referencesPage'),
  'group graph copy skips foreign-page groups fail-closed');

// --- Harmony：历史动作 ---
check(/DUPLICATE_PAGE = \d+,/.test(undoRedo),
  'UndoableActionType.DUPLICATE_PAGE exists');
check(undoRedo.includes('export interface DuplicatePageAction extends ActionBase'),
  'DuplicatePageAction interface exists');
check(undoRedo.includes('commitDuplicatePageContent: (pageId: string, snapshot: PageContentSnapshot'),
  'EditorHistoryBridge exposes commitDuplicatePageContent');
check(undoRedo.includes('type === UndoableActionType.DUPLICATE_PAGE'),
  'undo/redo memory accounting covers duplicate actions');

// --- Harmony：画布桥接 ---
check(canvas.includes('commitDuplicatePageContent: async (pageId: string, snapshot: PageContentSnapshot'),
  'canvas wires commitDuplicatePageContent into the bridge');
check(canvas.includes('originalGroupGraphForPageCopy(this.selectionGroups, leafIds)'),
  'canvas derives the page group graph for the copy');
check(canvas.includes('duplicate page content source is stale'),
  'canvas rejects stale content snapshots');
check(canvas.includes('type === UndoableActionType.DUPLICATE_PAGE'),
  'canvas routes duplicate actions through page history');

// --- Harmony：页面层 ---
check(notePage.includes('private async duplicateCurrentPage()'),
  'NotePage.duplicateCurrentPage exists');
check(notePage.includes('await historyBridge.flushCurrentPage()'),
  'duplicate flushes the source page before capture');
check(notePage.includes('historyBridge.captureCurrentPage()'),
  'duplicate captures the full page content snapshot');
check(notePage.includes('await this.pageRepo.duplicatePage(\n      this.noteId, sourcePageId, history)'),
  'duplicate calls the repository with history metadata');
check(notePage.includes('historyBridge.commitDuplicatePageContent(duplicated.pageId, snapshot, history)'),
  'duplicate commits the copied content onto the new page');
check(notePage.includes('this.selectPageById(duplicated.pageId)'),
  'duplicate selects the new copy');
check(notePage.includes('private async applyDuplicatePageHistory'),
  'applyDuplicatePageHistory exists');
check(notePage.includes('await this.pageRepo.deletePage(this.noteId, action.pageId, history)'),
  'duplicate undo hides the copy through the page-visibility write');
check(notePage.includes('await this.pageRepo.restoreDuplicatedPage(this.noteId, action.pageId, history)'),
  'duplicate redo restores the copy');
check(notePage.includes('duplicate page is not inserted after its source') === false &&
  notePage.includes('targetOrder[sourceIndex + 1] === action.pageId'),
  'duplicate validation enforces the after-source anchor');

// --- Harmony：UI ---
check(pageBar.includes('onDuplicatePage: () => void'),
  'PageManagerBar exposes the onDuplicatePage callback');
check(pageBar.includes("$r('app.string.duplicate_page')"),
  'PageManagerBar menu lists the Duplicate action');
check(pageBar.includes('this.onDuplicatePage()'),
  'Duplicate menu item invokes the callback');
check(notePage.includes('onDuplicatePage: () => {') &&
  notePage.includes('this.duplicateCurrentPage()'),
  'NotePage wires the menu callback through runPageOperation');
check(stringsBase.includes('"duplicate_page"') && stringsBase.includes('"Duplicate"'),
  'base resources carry the Duplicate label');
check(stringsZh.includes('"duplicate_page"') && stringsZh.includes('复制页面'),
  'zh_CN resources carry the localized Duplicate label');

console.log(`D04_ORIGINAL_PAGE_DUPLICATE_REPLAY_OK TOTAL=${total} FAILED=0`);
