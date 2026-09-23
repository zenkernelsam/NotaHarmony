// Phase 646 — 页面管理面板内页搜索（原版 qd2.isSearchActive/
// searchQuery/searchMatchingPageKeys）。
// 原版派发链（decompiled_1.0.3）：
//   r22 case24 → go5.b(ue4.A 图标, content_manager_search="Search") 行
//     激活 de2.l()：qd2.a(...,isSearchActive=true,...,mask 447)；
//   de2.s(query) → qd2.searchQuery=h + xd9.d 查询流 → sl case9 把命中
//     页键集合写回 qd2.i（searchMatchingPageKeys）；
//   qd2.c() 尾段：`if (!this.g || lvd.E0(this.h)) return list;`
//     （未激活或 query 空白 → 返回 nd2 过滤结果），否则
//     `this.i.contains(z5c.Z(pd2.a))` 逐页求交。
// Harmony 对齐：
//   * PageOverviewPanel 头部 🔍 开关（cd_pages_panel_search）→
//     searchActive；激活时渲染 TextInput（pages_panel_search_
//     placeholder，a11y=pages_panel_search=content_manager_search）；
//   * onChange → runSearch()：generation 防乱序，空白 query 立即清空
//     命中集；
//   * StrokePersistence.searchPageIdsWithText：search_item 按
//     note_id + folded_text LIKE 取 DISTINCT page_id；
//   * visibleItems() 尾段按 qd2.c() 语义求交（命中集未回 → 空集
//     fail-closed，与原版初始空集一致）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const strings = fs.readFileSync(`${originalRoot}resources/res/values/strings.xml`, 'utf8');
const qd2 = fs.readFileSync(`${originalRoot}sources/defpackage/qd2.java`, 'utf8');
const de2 = fs.readFileSync(`${originalRoot}sources/defpackage/de2.java`, 'utf8');
const sl = fs.readFileSync(`${originalRoot}sources/defpackage/sl.java`, 'utf8');
const r22 = fs.readFileSync(`${originalRoot}sources/defpackage/r22.java`, 'utf8');

const panel = fs.readFileSync('note/src/main/ets/ui/editor/PageOverviewPanel.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const persistence = fs.readFileSync('note/src/main/ets/data/StrokePersistence.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const strBase = fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const strZh = fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}

// --- 原版证据 ---
check(strings.includes('name="feature_note__content_manager_search">Search'),
  'original panel exposes a "Search" row label');
check(qd2.includes('isSearchActive=') && qd2.includes('searchQuery=') &&
  qd2.includes('searchMatchingPageKeys='),
  'qd2 UiState carries search active/query/matching-key fields');
check(qd2.includes('if (!this.g || lvd.E0(this.h))') &&
  qd2.includes('this.i.contains(z5c.Z(((pd2) obj3).a))'),
  'qd2.c() intersects the filtered list with matching page keys when search is active and non-blank');
check(de2.includes('public final void l()') &&
  de2.includes('447'),
  'de2.l() activates the search flag on the panel state');
check(de2.includes('public final void s(String str)') &&
  de2.includes('xd9Var.d'),
  'de2.s(query) pushes the query into the search flow');
check(sl.includes('qd2.a((qd2) value, null, null, null, null, false, null, false, null, set2'),
  'sl case9 writes the matching page-key set back into qd2.i');
check(r22.includes('content_manager_search'),
  'r22 renders the content-manager Search entry');

// --- Harmony：持久层 ---
check(persistence.includes('async searchPageIdsWithText(noteId: string, query: string)') &&
  persistence.includes('Promise<Set<string>>'),
  'StrokePersistence exposes per-page text search');
check(persistence.includes('SELECT DISTINCT page_id FROM search_item') &&
  persistence.includes('page_id IS NOT NULL') &&
  persistence.includes("folded_text LIKE ? ESCAPE '\\\\'"),
  'page search queries search_item folded_text per page');
check(persistence.includes('foldSearchText(query).trim()') &&
  persistence.includes('escapeSearchLike(folded)'),
  'page search folds and LIKE-escapes the query');
check(persistence.indexOf('searchPageIdsWithText') > 0 &&
  persistence.includes("if (folded.length === 0)"),
  'blank queries short-circuit to an empty match set');

// --- Harmony：面板 ---
check(panel.includes('@State private searchActive') &&
  panel.includes('@State private searchQuery') &&
  panel.includes('@State private matchingPageIds'),
  'panel owns isSearchActive/searchQuery/matchingPageIds state');
check(panel.includes('this.searchActive && this.searchQuery.trim().length > 0') &&
  panel.includes('!this.matchingPageIds.has(page.pageId)'),
  'visibleItems intersects with matching page ids only when search is active and non-blank (qd2.c parity)');
check(panel.includes("Button('🔍')") &&
  panel.includes('cd_pages_panel_search') &&
  panel.includes('this.searchActive = !this.searchActive;'),
  'header renders the search toggle with its a11y label');
check(panel.includes('TextInput({ placeholder: $r(\'app.string.pages_panel_search_placeholder\')') &&
  panel.includes('this.runSearch();'),
  'activating search reveals a TextInput feeding runSearch');
check(panel.includes('searchGeneration') &&
  panel.includes('generation !== this.searchGeneration'),
  'search results are generation-guarded against out-of-order delivery');
check(panel.includes('searchPageIdsWithText(this.noteId, query)'),
  'runSearch delegates to the persistence layer');
check(panel.includes('this.searchQuery = \'\';') &&
  panel.includes('this.matchingPageIds = new Set<string>()'),
  'deactivating search clears query and matches');

// --- 字符串资源（双语） ---
for (const name of ['pages_panel_search', 'cd_pages_panel_search',
  'pages_panel_search_placeholder']) {
  check(strBase.includes(`"name": "${name}"`), `base locale defines ${name}`);
  check(strZh.includes(`"name": "${name}"`), `zh_CN locale defines ${name}`);
}

console.log(`D05_ORIGINAL_PAGE_OVERVIEW_SEARCH_REPLAY_OK TOTAL=${total} FAILED=0`);
