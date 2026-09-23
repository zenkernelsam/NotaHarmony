// Phase 650 — 面板页操作不移动查看页 + 批量 Duplicate 锚定选中集末页。
// 原版证据（decompiled_1.0.3）：
//   ae2.java / e2.java 全文零 qd2 引用——批操作（Copy/Cut/Delete/
//   Duplicate/Clear/Bookmark）与 Paste 都不写 UiState.currentPageIndex；
//   de2.j(list) 反向扫描页表返回「页序上最后一张选中页」作为
//   m1d.c0 的单一插入锚点（ae2 v5 duplicate）；
//   fd2 case3 → zd2(de2,cxc,0)：加页仅在 cell 菜单可达（zd2 无其它
//   实例化点），invokeSuspend 未反编译——不导航语义按姊妹变体
//   v1(rotate, 不导航) 与面板管理面语义推定，登记于 ADR-0617。
// Harmony 对齐：addPageAt/duplicatePageAt/pasteCopiedPageAt 不再
// 跳转到新页，按页键锚定原查看页（与 deletePageAt 同一约定）；
// 批量 Duplicate 经 capturePageCopyPayload + pasteOneCopiedPage
// 把副本组插在选中集末页之后（升序保持源序）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const ae2 = fs.readFileSync(`${originalRoot}sources/defpackage/ae2.java`, 'utf8');
const e2 = fs.readFileSync(`${originalRoot}sources/defpackage/e2.java`, 'utf8');
const de2 = fs.readFileSync(`${originalRoot}sources/defpackage/de2.java`, 'utf8');
const fd2 = fs.readFileSync(`${originalRoot}sources/defpackage/fd2.java`, 'utf8');

const notePage = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
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

// --- 原版证据 ---
check(!ae2.includes('qd2'),
  'ae2 (all batch-op variants) never references qd2 — no currentPageIndex write');
check(!e2.includes('qd2'),
  'e2 (paste coroutine) never references qd2');
check(de2.includes('listIterator = list2.listIterator(list2.size())') &&
  de2.includes('!list.contains(new tz9(((fw4) objPrevious).a.v()))'),
  'de2.j scans the page list backwards for the last selected page (insert anchor)');
check(ae2.includes('cxc cxcVarJ = de2.j(de2Var, x09Var4, list)') &&
  ae2.includes('m1dVar5.c0(x09Var4, arrayListE3, cxcVarJ, dofVar5'),
  'ae2 v5 applies all copies at the single de2.j anchor');
check(fd2.includes('new zd2(de2Var, cxcVar2, null, 0)'),
  'fd2 case3 add routes through the panel-only zd2 variant 0');

// --- Harmony：不导航 ---
const add = section(notePage, '  private async addPageAt(', '  private async deleteCurrentPage(');
check(!add.includes('this.currentPageIndex = insertIndex') &&
  !add.includes('this.currentPageIndex = this.pages.findIndex('),
  'addPageAt no longer jumps to the inserted index');
check(add.includes('action.selectedPageIdAfter = selectedBefore') &&
  add.indexOf('this.selectPageById(selectedBefore);') > add.indexOf('this.pages = updated;'),
  'add keeps the viewed page anchored by id after the splice');

const dup = section(notePage, '  private async duplicatePageAt(', '  private canPasteCopiedPage(');
check(dup.includes('const selectedBefore: string = this.pages[this.currentPageIndex].pageId') &&
  dup.includes('this.selectPageById(selectedBefore);') &&
  !dup.includes('this.selectPageById(duplicated.pageId)'),
  'duplicate keeps the viewed page instead of selecting the copy');

const paste = section(notePage, '  private async pasteCopiedPageAt(', '  private async applyPageHistory(');
check(paste.includes('const selectedBefore: string = this.pages[this.currentPageIndex].pageId') &&
  paste.match(/for \(const payload of payloads\) \{\s*\n\s*anchorIndex = await this\.pasteOneCopiedPage\(anchorIndex, payload\);\s*\n\s*\}\s*\n\s*this\.selectPageById\(selectedBefore\);/) !== null,
  'batch paste restores the viewed page once after the insert loop');
check(!paste.includes('this.selectPageById(pasted.pageId)'),
  'pasteOneCopiedPage no longer navigates per inserted page');

// --- Harmony：批量 duplicate 锚定 ---
const dispatch = section(notePage, 'private dispatchPageSelectionAction(', 'applyNoteBackgroundSettings');
check(dispatch.match(/case 'duplicate':[\s\S]*?let anchorIndex: number = indices\[indices\.length - 1\];[\s\S]*?capturePageCopyPayload\(index\)[\s\S]*?pasteOneCopiedPage\(anchorIndex, payload\)/) !== null,
  'batch duplicate anchors all copies after the last selected page, ascending source order');

// --- 既有语义保持 ---
check(notePage.includes('orderAfter[Math.min(pageIndex, orderAfter.length - 1)]'),
  'current-page delete still resolves the neighbor selection');
check(notePage.includes('const selectedAfter: string = !isCurrent ? selectedBefore'),
  'non-current delete already keeps the viewed page (Phase 647 convention)');

console.log(`D05_ORIGINAL_PANEL_OPS_VIEWED_PAGE_REPLAY_OK TOTAL=${total} FAILED=0`);
