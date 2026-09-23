// Phase 649 — 非当前页 Clear Page 持久层落地（原版 ae2 variant 1 对齐）。
// 原版证据（decompiled_1.0.3）：
//   fd2 case1 → de2.n(list)：Clear Pages 批入口，空集 fail-closed；
//   ae2 case1：对每页收集 j.m(page).keySet() 全部元素键 →
//     u5j.l(x09, ids, null, 14) 实体删除 op → x82.I 记帐通道（可撤销）；
//   tc2 default(case6)：批量 Clear 调 de2.n(selectedPageIds)。
// Harmony 对齐：
//   * 当前页仍走画布 clearPageSignal（选择→删除→撤销一体管线）；
//   * 非当前页经 StrokePersistence.clearOriginalPageContent：
//     ORIGINAL_DELETE_ENTITIES 可见性删除全量元素（含被覆盖组）+
//     DELETE_ELEMENTS 页变更 companion（history 挂 actionId → 重启物化
//     为 PERSISTED_PAGE_MUTATIONS，撤销经导航+回放还原）；
//   * cell 菜单 Clear 不再限当前页；选择工具条 Clear 对任意非空
//     选中集可用（逐页 clearPageAt）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const de2 = fs.readFileSync(`${originalRoot}sources/defpackage/de2.java`, 'utf8');
const ae2 = fs.readFileSync(`${originalRoot}sources/defpackage/ae2.java`, 'utf8');
const fd2 = fs.readFileSync(`${originalRoot}sources/defpackage/fd2.java`, 'utf8');
const n9j = fs.readFileSync(`${originalRoot}sources/defpackage/n9j.java`, 'utf8');

const persistence = fs.readFileSync('note/src/main/ets/data/StrokePersistence.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const notePage = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const panel = fs.readFileSync('note/src/main/ets/ui/editor/PageOverviewPanel.ets', 'utf8')
  .replaceAll('\r\n', '\n');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}

// --- 原版证据 ---
check(de2.includes('public final void n(List list)') &&
  de2.includes('Clear pages with empty page selection'),
  'de2.n clears the given page set, empty-guarded');
check(fd2.includes('de2Var.n(m18.l0'),
  'fd2 case1 dispatches Clear to de2.n');
check(ae2.includes('u5j.l(x09Var2, arrayList, null, 14)') &&
  ae2.includes('x82.I(m1dVar2, listL1, dofVar2'),
  'ae2 v1 emits a delete-entities op through the journaled x82.I channel');
check(ae2.includes('au1.O0(arrayList') && ae2.includes('.keySet()'),
  'ae2 v1 collects every element key of each cleared page');
check(n9j.includes('de2Var3.n(au1.T1'),
  'tc2 default case dispatches batch clear over the selection');

// --- Harmony：持久层清空 ---
check(persistence.includes('async clearOriginalPageContent(noteId: string, pageId: string'),
  'StrokePersistence exposes a persisted page clear');
check(persistence.includes('readEligibleOriginalInkPage(store, noteId, pageId) === null') &&
  persistence.includes('clear page is not original-aligned'),
  'clear is gated on original-aligned pages');
check(persistence.match(/clearOriginalPageContent[\s\S]*?loadCurrentSnapshot\(store, noteId, pageId\)[\s\S]*?current\.length === 0/) !== null,
  'clear on an empty page is a no-op (returns null)');
check(persistence.includes('createPageMutation(\n          pageId, currentRevision, currentRevision + 1, current, [])'),
  'clear builds a DELETE_ELEMENTS mutation emptying the page');
check(persistence.match(/clearOriginalPageContent[\s\S]*?ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE/) !== null &&
  persistence.match(/clearOriginalPageContent[\s\S]*?OriginalDeleteEntitiesOperationApplier/) !== null,
  'clear deletes all element entities through the visibility op');
check(persistence.match(/clearOriginalPageContent[\s\S]*?group\.members\.every/) !== null,
  'clear also deletes groups fully covered by the page deletion');
check(persistence.match(/clearOriginalPageContent[\s\S]*?OpType\.DELETE_ELEMENTS[\s\S]*?encodePageMutationOp\(mutation\)[\s\S]*?history: stableHistory/) !== null,
  'clear journals a DELETE_ELEMENTS companion carrying the action history');
check(persistence.match(/clearOriginalPageContent[\s\S]*?rebuildPageSearchState/) !== null,
  'clear rebuilds the page search state for the emptied page');

// --- Harmony：NotePage 分发 ---
check(notePage.includes('private async clearPageAt(pageIndex: number)') &&
  notePage.includes('this.clearPageSignal++') &&
  notePage.includes('clearOriginalPageContent('),
  'clearPageAt routes current→canvas signal, non-current→persisted clear');
check(notePage.includes('type: UndoableActionType.PERSISTED_PAGE_MUTATIONS') &&
  notePage.includes('operations: [operation]'),
  'non-current clear pushes a PERSISTED_PAGE_MUTATIONS history action');
check(notePage.includes("case 'clear':\n          await this.clearPageAt(pageIndex);"),
  'cell-menu clear dispatches through the parameterized path');
check(notePage.match(/case 'clear':[\s\S]*?indicesOf\(\)[\s\S]*?clearPageAt\(index\)/) !== null,
  'batch clear iterates the whole selection');

// --- Harmony：面板 ---
check(!panel.includes('if (this.selected) {') ||
  !panel.match(/if \(this\.selected\) \{\s*\n\s*MenuItem\(\{ content: \$r\('app\.string\.clear_page'\)/),
  'cell-menu clear is no longer gated on the current page');
check(panel.match(/SelectionActionChip\(\$r\('app\.string\.clear_page'\)[\s\S]*?selectedPageIds\.length > 0/) !== null,
  'selection-bar clear is enabled for any non-empty selection');

console.log(`D05_ORIGINAL_PAGE_CLEAR_PERSISTED_REPLAY_OK TOTAL=${total} FAILED=0`);
