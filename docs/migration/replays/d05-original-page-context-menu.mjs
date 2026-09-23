// Phase 647 — 页面管理面板 cell 上下文菜单（原版 n9j 菜单 → fd2 dispatch）。
// 原版证据（decompiled_1.0.3）：
//   n9j 菜单序：Add page、Cut、Copy、[Paste]、Duplicate、[Rotate Page]、
//     [Create Template(flag ac4.w0)]、Clear Page、分隔线、Delete；
//   fd2 dispatch：case0=选中开关（qd2.f ± tz9）、case1=de2.n Clear、
//     case2=de2.q Delete、case3=zd2 v0 Add Page、case4=de2.p Cut、
//     case5=de2.o Copy、case6=e2 v16 Paste、case7=de2.r Duplicate、
//     default=zd2 v1 Rotate Page。
// Harmony 对齐：
//   * PageOverviewCell 长按 bindContextMenu 渲染同一序的 MenuItem
//     （Create Template 上游 flag 关闭故缺席；Clear 仅当前页——
//     画布信号管线 fail-closed）；
//   * onPageAction → NotePage.dispatchPageContextAction →
//     runPageOperation 门禁下的参数化页操作（addPageAt/cutPageAt/
//     copyPageAt/pasteCopiedPageAt/duplicatePageAt/rotatePageAt/
//     deletePageAt）；非当前页快照经 persistedPageSnapshot/
//     persistedPageCopyPlan（page_element_snapshot 重建）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const strings = fs.readFileSync(`${originalRoot}resources/res/values/strings.xml`, 'utf8');
const n9j = fs.readFileSync(`${originalRoot}sources/defpackage/n9j.java`, 'utf8');
const fd2 = fs.readFileSync(`${originalRoot}sources/defpackage/fd2.java`, 'utf8');

const panel = fs.readFileSync('note/src/main/ets/ui/editor/PageOverviewPanel.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const notePage = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}

// --- 原版证据 ---
check(strings.includes('content_manager_add_page') &&
  strings.includes('content_manager_cut') &&
  strings.includes('content_manager_copy') &&
  strings.includes('content_manager_paste') &&
  strings.includes('content_manager_duplicate') &&
  strings.includes('content_manager_rotate_page') &&
  strings.includes('content_manager_clear_page') &&
  strings.includes('content_manager_delete'),
  'original cell menu strings exist');
check(n9j.indexOf('content_manager_add_page') < n9j.indexOf('content_manager_cut') &&
  n9j.indexOf('content_manager_cut') < n9j.indexOf('content_manager_copy') &&
  n9j.indexOf('content_manager_copy') < n9j.indexOf('content_manager_paste') &&
  n9j.indexOf('content_manager_paste') < n9j.indexOf('content_manager_duplicate') &&
  n9j.indexOf('content_manager_duplicate') < n9j.indexOf('content_manager_rotate_page') &&
  n9j.indexOf('content_manager_rotate_page') < n9j.indexOf('content_manager_clear_page'),
  'original menu order is add/cut/copy/paste/duplicate/rotate/clear');
check(n9j.includes('lc4.a(ac4.w0)') && n9j.includes('content_manager_create_template'),
  'create-template stays flag-gated upstream');
check(fd2.includes('de2Var.n(m18.l0') && fd2.includes('de2Var.q(m18.l0') &&
  fd2.includes('de2Var.p(m18.l0') && fd2.includes('de2Var.o(m18.l0') &&
  fd2.includes('de2Var.r(m18.l0'),
  'fd2 dispatches clear/delete/cut/copy/duplicate to de2 bulk ops');
check(fd2.includes('new zd2(de2Var, cxcVar2, null, 0)') &&
  fd2.includes('new zd2(de2Var, cxcVar3, null, 1)'),
  'fd2 case3/default dispatch add-page (zd2 v0) and rotate (zd2 v1)');
check(fd2.includes('new e2(16, null, de2Var'),
  'fd2 case6 dispatches paste via e2 variant 16');
check(fd2.includes('qd2Var.f.contains(new tz9(cxcVar))') &&
  fd2.includes('ys2.G(set') && fd2.includes('ys2.K(set'),
  'fd2 case0 toggles the page key inside qd2.selectedPageIds');

// --- Harmony：面板菜单 ---
check(panel.includes('bindContextMenu(this.buildCellMenu(), ResponseType.LongPress)'),
  'cells open the context menu on long-press');
check(panel.includes("MenuItem({ content: $r('app.string.add_page') })") &&
  panel.includes("MenuItem({ content: $r('app.string.cut_page') })") &&
  panel.includes("MenuItem({ content: $r('app.string.copy_page') })") &&
  panel.includes("MenuItem({ content: $r('app.string.duplicate_page') })") &&
  panel.includes("MenuItem({ content: $r('app.string.delete_page') })"),
  'the cell menu renders add/cut/copy/duplicate/delete items');
check(panel.indexOf("'add'") < panel.indexOf("'cut'") &&
  panel.indexOf("'cut'") < panel.indexOf("'copy'") &&
  panel.indexOf("'copy'") < panel.indexOf("'paste'") &&
  panel.indexOf("'paste'") < panel.indexOf("'duplicate'") &&
  panel.indexOf("'duplicate'") < panel.indexOf("'rotate'") &&
  panel.indexOf("'rotate'") < panel.indexOf("'clear'") &&
  panel.indexOf("'clear'") < panel.indexOf("'delete'"),
  'menu order mirrors the original n9j sequence');
check(panel.includes('if (this.canPaste)') &&
  panel.includes('rotatedOriginalPageInfo(this.page) !== null') &&
  panel.includes('if (this.selected)'),
  'paste/rotate/clear items keep the original conditional visibility');
check(!panel.includes('create_template'),
  'create-template stays absent (flag-disabled upstream)');
check(panel.includes('onPageAction: (pageIndex: number, action: string)') &&
  panel.includes('canPastePages: boolean'),
  'panel exposes the action callback and paste gate');

// --- Harmony：NotePage 分发与参数化操作 ---
check(notePage.includes('dispatchPageContextAction(pageIndex, action)'),
  'panel actions route through the context dispatcher');
check(notePage.includes("case 'add':\n          await this.addPageAt(pageIndex)") &&
  notePage.includes("case 'cut':\n          await this.cutPageAt(pageIndex)") &&
  notePage.includes("case 'copy':\n          await this.copyPageAt(pageIndex)") &&
  notePage.includes("case 'paste':\n          await this.pasteCopiedPageAt(pageIndex)") &&
  notePage.includes("case 'duplicate':\n          await this.duplicatePageAt(pageIndex)") &&
  notePage.includes("case 'rotate':\n          await this.rotatePageAt(pageIndex)") &&
  notePage.includes("case 'delete':\n          await this.deletePageAt(pageIndex)"),
  'every fd2 action maps to a parameterized page op');
check(notePage.includes("if (pageIndex === this.currentPageIndex") &&
  notePage.includes("this.clearPageSignal++;"),
  'clear only fires the canvas signal for the current page');
check(notePage.includes('await this.addPageAt(this.currentPageIndex)') &&
  notePage.includes('await this.deletePageAt(this.currentPageIndex)') &&
  notePage.includes('await this.copyPageAt(this.currentPageIndex)') &&
  notePage.includes('await this.cutPageAt(this.currentPageIndex)') &&
  notePage.includes('await this.pasteCopiedPageAt(this.currentPageIndex)') &&
  notePage.includes('await this.duplicatePageAt(this.currentPageIndex)') &&
  notePage.includes('await this.rotatePageAt(this.currentPageIndex)'),
  'current-page ops delegate to the parameterized variants');
check(notePage.includes('persistedPageSnapshot(') &&
  notePage.includes('persistedPageCopyPlan(') &&
  notePage.includes('originalGroupGraphForPageCopy(loaded.groups, leafIds)'),
  'non-current pages rebuild snapshots from page_element_snapshot');
check(notePage.includes('this.pages[this.currentPageIndex].pageId') &&
  notePage.includes('!isCurrent ? selectedBefore'),
  'non-current deletes keep the selection on the current page');
check(notePage.includes('this.pageRepo.addPage(\n      this.noteId, page, history, anchorPageId)') ||
  notePage.includes('anchorPageId'),
  'context add-page anchors the insert after the tapped page');

console.log(`D05_ORIGINAL_PAGE_CONTEXT_MENU_REPLAY_OK TOTAL=${total} FAILED=0`);
