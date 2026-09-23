// Phase 637 — Add Page 插入位置对齐（原版 n9j Add Page = 选中页后插入）。
// 原版派发链（decompiled_1.0.3）：
//   n9j.c 菜单首项 feature_note__content_manager_add_page -> c.function0
//   -> n9j.g function3 -> id2 new fd2(de2, pd2, 3) -> fd2 case 3
//   -> new zd2(de2, cxc, null, 0)（zd2 协程变体 0；变体 1 = Rotate Page）
//   -> zd2.invokeSuspend：遍历 a79.i 定位选中页下标 r12，
//      u5j.i(x09, r12 + 1, 0, 14) 生成插入 op（JADX debug 指令转储，
//      zd2 结构化输出失败但 u5j.i / fd2 / id2 / n9j.c 均已正常反编译互证）。
// u5j.i(x09, i, i2, i3)：
//   * bfj.b(f1aVar.b, i, f1aVar.h) 解析插入下标 i 处的序列锚点；
//   * haj.a(cxcVarB, null, i2, oz9.UNBOOKMARKED, 16)：nz9 = null ——
//     新页继承笔记默认背景（不复制当前页背景），bookmark = UNBOOKMARKED，
//     i3 & 4 != 0 → i2 = 1（单页）。
// Harmony 对齐：
//   * persistOriginalCreatePage(s) 增加 afterPageId 锚点（readPageIdentity），
//     缺省保留 readTailPosition 尾部行为；
//   * PageRepositoryImpl.addPage(afterPageId) 原版路径锚点后插入并校验
//     落点 = anchorIndex + 1，legacy 路径按 page_index 倒序平移腾位；
//   * NotePage.addPage orderAfter 在 currentPageIndex + 1 处 splice；
//   * PersistentHistory CREATE_PAGE 物化与 applyAddPageHistory 不再要求
//     尾部落点（isSinglePageTransition 本身位置无关）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const n9j = fs.readFileSync(`${originalRoot}n9j.java`, 'utf8');
const id2 = fs.readFileSync(`${originalRoot}id2.java`, 'utf8');
const fd2 = fs.readFileSync(`${originalRoot}fd2.java`, 'utf8');
const zd2 = fs.readFileSync(`${originalRoot}zd2.java`, 'utf8');
const u5j = fs.readFileSync(`${originalRoot}u5j.java`, 'utf8');

const persistence = fs.readFileSync('note/src/main/ets/data/OriginalPagePersistence.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const repo = fs.readFileSync('note/src/main/ets/data/PageRepositoryImpl.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const repoIf = fs.readFileSync('note/src/main/ets/data/RepositoryInterfaces.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const history = fs.readFileSync('note/src/main/ets/data/PersistentHistory.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const notePage = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}

// --- 原版证据：菜单项与派发链 ---
check(n9j.includes('R.string.feature_note__content_manager_add_page') &&
  n9j.includes('R.drawable.ui_designsystem__add_page'),
  'original menu exposes feature_note__content_manager_add_page');
check(n9j.indexOf('content_manager_add_page') < n9j.indexOf('content_manager_cut'),
  'add_page is the first page menu item (before cut)');
check(n9j.includes('Function0 function9 = function0'),
  'add_page menu item binds n9j.c function0');
check(id2.includes('objS5 = new fd2(de2Var, pd2Var, 3);'),
  'id2 builds the add-page callback as fd2 argument 3');
check(fd2.includes('case 3:') && fd2.includes('new zd2(de2Var, cxcVar2, null, 0)'),
  'fd2 case 3 launches zd2 coroutine variant 0');
check(zd2.includes('case 0:') && zd2.includes('new zd2(de2Var, cxcVar, ef2Var, 0)'),
  'zd2 variant 0 exists on the shared page-mutation dispatcher');
check(u5j.includes('public static ln2 i(x09 x09Var, int i, int i2, int i3)'),
  'u5j.i is the create-page-at-index op builder');
check(u5j.includes('cxc cxcVarB = bfj.b(f1aVar.b, i, f1aVar.h)'),
  'u5j.i resolves the sequence anchor at insertion index i via bfj.b');
check(u5j.includes('haj.a(cxcVarB, null, i2, oz9.UNBOOKMARKED, 16)'),
  'u5j.i emits ln2 with null nz9 (note-default background) and UNBOOKMARKED');
check(u5j.includes('if ((i3 & 4) != 0)') && u5j.includes('i2 = 1;'),
  'u5j.i mask 14 forces a single-page create');

// --- Harmony：原版路径锚点插入 ---
check(persistence.includes('afterPageId: string | null = null'),
  'persistOriginalCreatePage(s) accept an optional afterPageId anchor');
check(persistence.includes('await readPageIdentity(store, noteId, afterPageId)') &&
  persistence.includes('await readTailPosition(store, noteId)'),
  'anchor resolves to the predecessor identity, default stays tail');
check(repo.includes('async addPage(noteId: string, page: PageInfo, history?: HistoryMetadata,\n    afterPageId?: string)'),
  'addPage exposes the afterPageId anchor');
check(repo.includes('persistOriginalCreatePage(store, noteId, null,'),
  'original add path creates the anchored page with a null nz9');
check(repo.includes("'original CreatePage did not land after its anchor'"),
  'original add path asserts the materialized index is anchor + 1');
check(repo.includes('assignedPage.pageIndex = Math.min(Math.max(assignedPage.pageIndex, 0), before.length)'),
  'legacy add path clamps the requested index for redo/imports');
check(repo.includes('existing.pageIndex >= assignedPage.pageIndex') &&
  repo.includes('existing.pageIndex + 1'),
  'legacy add path shifts following page_index values to make room');
check(repoIf.includes('afterPageId?: string'),
  'PageRepository interface documents the anchor parameter');

// --- Harmony：历史物化与回放开窗 ---
check(history.includes('persistent ADD_PAGE was not an empty single-page action') &&
  !history.includes('persistent ADD_PAGE was not an empty tail-page action'),
  'persistent CREATE_PAGE materialization accepts non-tail inserts');
check(notePage.includes('const insertIndex: number = pageIndex + 1') &&
  notePage.includes('await this.addPageAt(this.currentPageIndex)'),
  'NotePage.addPage computes the selectedIndex + 1 insertion point');
check(notePage.includes('orderBefore.slice(0, insertIndex).concat('),
  'pageOrderAfter splices the new page id after the current page');
check(notePage.includes('this.noteId, page, history, anchorPageId'),
  'live add passes the anchor page as the insertion anchor');
check(notePage.includes('updated.splice(insertIndex, 0, assignedPage)'),
  'in-memory page list splices the added page at the anchor position');
check(notePage.includes('this.currentPageIndex = insertIndex'),
  'selection moves to the newly added page');
check(!notePage.includes('action.pageOrderAfter[action.pageOrderAfter.length - 1] !== action.pageId'),
  'applyAddPageHistory no longer requires the tail position');
check(notePage.includes('this.countString(action.pageOrderAfter, action.pageId) !== 1'),
  'applyAddPageHistory still requires exactly one inserted membership');

console.log(`D04_ORIGINAL_ADD_PAGE_ANCHOR_REPLAY_OK TOTAL=${total} FAILED=0`);
