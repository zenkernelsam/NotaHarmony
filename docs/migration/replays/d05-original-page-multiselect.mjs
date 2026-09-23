// Phase 648 — 页面管理面板多选模式（原版 qd2.isSelecting/selectedPageIds
// + tfh 选择工具条 + dg2 多页剪贴板）。
// 原版证据（decompiled_1.0.3）：
//   qd2.UiState.e=isSelecting、f=selectedPageIds；
//   fd2 case0：选中集成员切换（ys2.K 并入 / ys2.G 移出）；
//   de2.u()：qd2.a(..., false, qw3.I, false, ..., 463) 一次复位
//     isSelecting/selectedPageIds/isSearchActive；
//   n9j tc2 7-case dispatch：Copy(0)+u()/Duplicate(1)/Delete(2)+u()/
//     Cut(3)+u()/Paste(4=e2 v16)/Bookmark(5)/Clear(6)，参数
//     au1.T1(selectedPageIds)；
//   n9j function9 case2 Select all = qd2.c() 过滤全集，case3 Deselect
//     all = 清空 + u()；
//   tfh 工具条串：content_manager_select_all/deselect_all/cut/paste/
//     bookmark/clear_page；s8 case1 = content_manager_select 菜单项；
//   dg2 = CopiedPagesData(ops:ArrayList, pageCount) —— 多页剪贴板。
// Harmony 对齐：
//   * PageOverviewPanel：selecting/selectedPageIds 状态、cell 菜单
//     "Select"、选择态 cell tap=成员切换、勾选指示、Select all/
//     Deselect all + 批量 Copy/Duplicate/Delete/Cut/Paste/Bookmark/
//     Clear(仅当前页 fail-closed) + Done；
//   * OriginalPageClipboard：copiedPages 有序多页记录；
//   * NotePage.dispatchPageSelectionAction：批操作复用参数化页操作，
//     变序操作降序索引执行；批粘贴锚定选中集末页。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const strings = fs.readFileSync(`${originalRoot}resources/res/values/strings.xml`, 'utf8');
const n9j = fs.readFileSync(`${originalRoot}sources/defpackage/n9j.java`, 'utf8');
const fd2 = fs.readFileSync(`${originalRoot}sources/defpackage/fd2.java`, 'utf8');
const de2 = fs.readFileSync(`${originalRoot}sources/defpackage/de2.java`, 'utf8');
const qd2 = fs.readFileSync(`${originalRoot}sources/defpackage/qd2.java`, 'utf8');
const dg2 = fs.readFileSync(`${originalRoot}sources/defpackage/dg2.java`, 'utf8');
const tfh = fs.readFileSync(`${originalRoot}sources/defpackage/tfh.java`, 'utf8');
const s8 = fs.readFileSync(`${originalRoot}sources/defpackage/s8.java`, 'utf8');

const panel = fs.readFileSync('note/src/main/ets/ui/editor/PageOverviewPanel.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const notePage = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const clipboard = fs.readFileSync('note/src/main/ets/rendering/OriginalPageClipboard.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const baseStrings = fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zhStrings = fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}

// --- 原版证据 ---
check(strings.includes('content_manager_select') &&
  strings.includes('content_manager_select_all') &&
  strings.includes('content_manager_deselect_all') &&
  strings.includes('content_manager_bookmark'),
  'original selection-mode strings exist');
check(qd2.includes('isSelecting=') && qd2.includes('selectedPageIds='),
  'qd2 UiState carries selection state');
check(de2.includes('false, qw3.I, false, null, null, 463'),
  'de2.u() resets isSelecting+selectedPageIds+isSearchActive in one flow write');
check(fd2.includes('qd2Var.f.contains(new tz9(cxcVar))') &&
  fd2.includes('ys2.G(set') && fd2.includes('ys2.K(set'),
  'fd2 case0 toggles the page key inside qd2.selectedPageIds');
check(n9j.includes('de2Var3.o(au1.T1') && n9j.includes('de2Var3.r(au1.T1') &&
  n9j.includes('de2Var3.q(au1.T1') && n9j.includes('de2Var3.p(au1.T1') &&
  n9j.includes('de2Var3.m(au1.T1') && n9j.includes('de2Var3.n(au1.T1') &&
  n9j.includes('new e2(16, null, de2Var3, au1.T1'),
  'tc2 dispatches copy/duplicate/delete/cut/bookmark/clear/paste over the sorted selection');
check(n9j.match(/de2Var3\.o\(au1\.T1[^\n]*\);\s*\n\s*de2Var3\.u\(\)/) !== null &&
  n9j.match(/de2Var3\.q\(au1\.T1[^\n]*\);\s*\n\s*de2Var3\.u\(\)/) !== null &&
  n9j.match(/de2Var3\.p\(au1\.T1[^\n]*\);\s*\n\s*de2Var3\.u\(\)/) !== null,
  'copy/delete/cut exit selection via de2.u() afterwards');
check(tfh.includes('content_manager_select_all') &&
  tfh.includes('content_manager_deselect_all') &&
  tfh.includes('content_manager_bookmark') &&
  tfh.includes('content_manager_clear_page'),
  'tfh toolbar renders select-all/deselect-all/bookmark/clear items');
check(s8.includes('content_manager_select'),
  's8 case1 renders the per-cell "Select" menu item');
check(dg2.includes('CopiedPagesData(ops=') && dg2.includes('ArrayList'),
  'dg2 page clipboard is an ordered multi-page record');

// --- Harmony：面板选择态 ---
check(panel.includes('@State private selecting: boolean') &&
  panel.includes('@State private selectedPageIds: string[]'),
  'panel holds isSelecting/selectedPageIds state');
check(panel.includes('private toggleSelectPage(pageId: string)') &&
  panel.includes('this.selectedPageIds.indexOf(pageId)') &&
  panel.includes('next.splice(index, 1)') && panel.includes('next.push(pageId)'),
  'toggleSelectPage mirrors fd2 case0 membership toggle');
check(panel.includes('private exitSelection()') &&
  panel.includes('this.selecting = false') &&
  panel.includes('this.selectedPageIds = []') &&
  panel.includes('this.searchActive = false'),
  'exitSelection mirrors de2.u() three-field reset');
check(panel.includes('private selectAllVisible()') &&
  panel.includes('for (const item of this.visibleItems())'),
  'select-all loads the filtered qd2.c() page set');
check(panel.includes("onSelectionAction: (action: string, pageIds: string[])"),
  'panel exposes the batch dispatch callback');
check(panel.includes("dispatchSelection('copy')") &&
  panel.includes("dispatchSelection('duplicate')") &&
  panel.includes("dispatchSelection('delete')") &&
  panel.includes("dispatchSelection('cut')") &&
  panel.includes("dispatchSelection('bookmark')"),
  'selection bar dispatches the tc2 batch ops');
check(panel.includes("action === 'copy' || action === 'delete' || action === 'cut'"),
  'copy/delete/cut exit selection afterwards (tc2 + u())');
check(panel.includes("$r('app.string.pages_select_all')") &&
  panel.includes("$r('app.string.pages_deselect_all')") &&
  panel.includes("$r('app.string.pages_done')"),
  'selection bar renders select-all/deselect-all/done');
check(panel.includes("MenuItem({ content: $r('app.string.pages_menu_select') })") &&
  panel.includes('this.onToggleSelect(this.pageIndex)'),
  'cell menu offers the original "Select" entry');
check(panel.includes('@Prop selecting: boolean') &&
  panel.includes('@Prop checked: boolean') &&
  panel.includes('onToggleSelect: (pageIndex: number)'),
  'cell carries selection-mode props');
check(panel.includes('if (this.selecting) {\n                    this.toggleSelectPage(item.page.pageId);'),
  'cell tap toggles membership while selecting');
check(panel.includes("this.selectedPageIds.filter(") &&
  panel.includes('onPagesChange'),
  'stale selection entries are pruned when the page list changes');

// --- Harmony：批量操作与多页剪贴板 ---
check(clipboard.includes('let copiedPages: CopiedPagePayload[]') &&
  clipboard.includes('storeCopiedPages(payloads: CopiedPagePayload[])') &&
  clipboard.includes('copiedPagePayloads(): CopiedPagePayload[]'),
  'page clipboard stores an ordered multi-page payload list');
check(notePage.includes('private dispatchPageSelectionAction(action: string, pageIds: string[])'),
  'NotePage exposes the batch selection dispatcher');
check(notePage.includes('capturePageCopyPayload(pageIndex)') &&
  notePage.includes('storeCopiedPages(payloads)'),
  'batch copy fills the clipboard with one payload per selected page');
check(notePage.includes('for (const index of indicesOf().reverse())'),
  'order-mutating batch ops iterate descending indices');
check(notePage.includes('await this.togglePageBookmarkAt(index)') &&
  notePage.includes('private async togglePageBookmarkAt(pageIndex: number)'),
  'batch bookmark rides the parameterized PAGE_BOOKMARK path');
check(notePage.includes('private async pasteOneCopiedPage(') &&
  notePage.includes('anchorIndex = await this.pasteOneCopiedPage(anchorIndex, payload)'),
  'multi-page paste inserts each payload after the running anchor');
check(notePage.includes('await this.pasteCopiedPageAt(indices[indices.length - 1])'),
  'batch paste anchors after the last selected page');
check(notePage.includes("case 'clear':") &&
  notePage.includes('await this.clearPageAt(index)'),
  'batch clear iterates the selection through the persisted/canvas clear path (Phase 649)');

// --- 字符串 ---
check(baseStrings.includes('"pages_menu_select"') &&
  baseStrings.includes('"pages_select_all"') &&
  baseStrings.includes('"pages_deselect_all"') &&
  baseStrings.includes('"pages_done"'),
  'base strings carry the selection labels');
check(zhStrings.includes('"pages_menu_select"') &&
  zhStrings.includes('"pages_select_all"') &&
  zhStrings.includes('"pages_deselect_all"') &&
  zhStrings.includes('"pages_done"'),
  'zh_CN strings carry the selection labels');

console.log(`D05_ORIGINAL_PAGE_MULTISELECT_REPLAY_OK TOTAL=${total} FAILED=0`);
