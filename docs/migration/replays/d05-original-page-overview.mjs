// Phase 645 — 页面管理面板（原版 content manager / qd2 页总览）。
// 原版派发链（decompiled_1.0.3）：
//   x90.g 顶栏首项 pq9.N → fh2(function0,z) → gs8 case2 渲染
//     content_manager_toggle（nti.e + pz2.g/h 开/关态图标）——
//     位于 undo/redo（p9f）之前；
//   面板 VM：qd2.UiState = currentPageIndex/pages/thumbnails/
//     selectedFilter/isSelecting/selectedPageIds/isSearchActive/
//     searchQuery/searchMatchingPageKeys；过滤枚举 nd2 =
//     ALL(0)/BOOKMARKS(1)/NOTES(2)（n9j:2212-2220 → filter_all/
//     filter_bookmarks/filter_notes 三 chip）；
//   标题 feature_note__content_manager_title="Pages"；空态
//     ui_pageselection__no_pages；关闭 a11y=close_description。
// Harmony 对齐（ADR-0612 子集）：
//   * EditorToolbar 顶栏首项 ▦ 页面面板开关（cd_pages_panel_toggle）；
//   * PageOverviewPanel：标题 Pages + 三过滤 chip（nd2 序）+
//     4 列缩略图栅格（ThumbnailRenderer 串行渲染链）+ 点击跳页 +
//     当前页高亮 + 书签角标 + 空态 + 显式关闭；
//   * NOTES chip 以 page_element_snapshot 行数判定（新增
//     StrokePersistence.getPageElementCounts）；
//   * 多选（isSelecting/selectedPageIds/tfh 工具条）与页内搜索
//     登记后续 Phase。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const strings = fs.readFileSync(`${originalRoot}resources/res/values/strings.xml`, 'utf8');
const qd2 = fs.readFileSync(`${originalRoot}sources/defpackage/qd2.java`, 'utf8');
const nd2 = fs.readFileSync(`${originalRoot}sources/defpackage/nd2.java`, 'utf8');
const n9j = fs.readFileSync(`${originalRoot}sources/defpackage/n9j.java`, 'utf8');
const gs8 = fs.readFileSync(`${originalRoot}sources/defpackage/gs8.java`, 'utf8');
const x90 = fs.readFileSync(`${originalRoot}sources/defpackage/x90.java`, 'utf8');

const panel = fs.readFileSync('note/src/main/ets/ui/editor/PageOverviewPanel.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const toolbar = fs.readFileSync('note/src/main/ets/ui/editor/EditorToolbar.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const notePage = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
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
check(strings.includes('name="feature_note__content_manager_title">Pages'),
  'original panel title is "Pages"');
check(strings.includes('content_manager_toggle_description') &&
  strings.includes('content_manager_close_description'),
  'original panel exposes toggle and close a11y labels');
check(strings.includes('content_manager_filter_all') &&
  strings.includes('content_manager_filter_bookmarks') &&
  strings.includes('content_manager_filter_notes'),
  'original filter chips are All/Bookmarks/Notes');
check(strings.includes('ui_pageselection__no_pages'),
  'original has an empty-state string');
check(qd2.includes('thumbnails=') && qd2.includes('selectedFilter=') &&
  qd2.includes('isSelecting=') && qd2.includes('selectedPageIds='),
  'qd2 UiState carries pages, thumbnails, filter and selection state');
check(nd2.includes('new nd2("ALL", 0)') && nd2.includes('new nd2("BOOKMARKS", 1)') &&
  nd2.includes('new nd2("NOTES", 2)'),
  'nd2 enumerates ALL/BOOKMARKS/NOTES in order');
check(n9j.includes('content_manager_filter_all') &&
  n9j.includes('content_manager_filter_bookmarks') &&
  n9j.includes('content_manager_filter_notes'),
  'n9j maps the three filter ordinals to their chips');
check(gs8.includes('content_manager_toggle_description'),
  'gs8 case 2 renders the content-manager toggle with its a11y label');
check(x90.indexOf('new fh2(function0, z)') < x90.indexOf('new p9f(wrdVar, i8)'),
  'the pages toggle renders before the undo/redo block in the top bar');

// --- Harmony：面板组件 ---
check(panel.includes("Text($r('app.string.pages_panel_title'))"),
  'panel renders the Pages title');
check(panel.includes("FilterChip($r('app.string.pages_filter_all'), FILTER_ALL)") &&
  panel.includes("FilterChip($r('app.string.pages_filter_bookmarks'), FILTER_BOOKMARKS)") &&
  panel.includes("FilterChip($r('app.string.pages_filter_notes'), FILTER_NOTES)"),
  'panel renders all three filter chips');
check(panel.indexOf('FILTER_ALL') < panel.indexOf('FILTER_BOOKMARKS') &&
  panel.includes('FILTER_BOOKMARKS: number = 1') &&
  panel.includes('FILTER_NOTES: number = 2'),
  'filter constants mirror the nd2 ordinals');
check(panel.includes('page.bookmarked !== true') &&
  panel.includes('!this.nonEmptyPageIds.has(page.pageId)'),
  'bookmarks/notes filters apply bookmark and element-count semantics');
check(panel.includes("columnsTemplate('1fr 1fr 1fr 1fr')"),
  'thumbnails lay out in a 4-column grid');
check(panel.includes('renderThumbnail(noteId, persistence, page, theme, database)'),
  'cells rasterize through the shared ThumbnailRenderer');
check(panel.includes('this.thumbChain = this.thumbChain.then'),
  'thumbnail renders serialize through a promise chain');
check(panel.includes('getPageElementCounts(this.noteId)'),
  'panel loads per-page element counts for the notes filter');
check(panel.includes("pages_panel_empty"),
  'empty filter result renders the no-pages string');
check(panel.includes('cd_pages_panel_close') &&
  panel.includes('this.onRequestClose();'),
  'panel carries a close button with the original a11y label');
check(panel.includes('this.onJumpToPage(pageIndex)'),
  'tapping a thumbnail jumps to that page');
check(panel.includes('item.index === this.currentPageIndex') &&
  panel.includes('this.selected ? 2 : 1'),
  'the current page cell draws an accent selection ring');
check(panel.includes("page?.bookmarked === true") &&
  panel.includes('bookmark_page'),
  'bookmarked cells render the bookmark badge');
check(panel.includes('aboutToDisappear') && panel.includes('renderer.dispose()') &&
  panel.includes('pm.release()'),
  'renderer and pixelmaps are released when the panel unmounts');
check(panel.includes('cellKey') && panel.includes('this.thumbRevision'),
  'cell keys carry the content-revision seed for re-rendering');

// --- Harmony：持久层与宿主接线 ---
check(persistence.includes('async getPageElementCounts(noteId: string)') &&
  persistence.includes('COUNT(*) AS element_count') &&
  persistence.includes('GROUP BY page_id'),
  'StrokePersistence exposes per-page element counts');
check(toolbar.includes("Button('▦')") &&
  toolbar.includes("cd_pages_panel_toggle"),
  'toolbar renders the pages-panel toggle with its a11y label');
check(toolbar.indexOf("Button('▦')") < toolbar.indexOf('visibleToolStates()') &&
  toolbar.indexOf("Button('▦')") < toolbar.indexOf("Button('↶')"),
  'the pages toggle sits first, before tools and undo/redo (pq9.N parity)');
check(toolbar.includes('onTogglePagesPanel: () => void'),
  'toolbar exposes the toggle callback');
check(notePage.includes('onTogglePagesPanel: () => {') &&
  notePage.includes('this.showPageOverview = !this.showPageOverview;'),
  'NotePage wires the toggle to the sheet state');
check(notePage.includes('bindSheet(this.showPageOverview, this.buildPageOverview()'),
  'the overview binds as a sheet on the editor column');
check(notePage.includes('PageOverviewPanel({') &&
  notePage.includes('thumbRevision: this.pageContentVersion') &&
  notePage.includes('currentPageIndex: this.currentPageIndex'),
  'panel receives pages, selection and the revision seed');
check(notePage.includes('this.pageContentVersion++;') &&
  notePage.indexOf('this.pageContentVersion++') >
  notePage.indexOf('this.canRedo = r;'),
  'content mutations bump the thumbnail revision seed');
check(notePage.includes('import { PageOverviewPanel }'),
  'NotePage imports the panel component');

// --- 字符串资源（双语） ---
for (const name of ['pages_panel_title', 'pages_filter_all',
  'pages_filter_bookmarks', 'pages_filter_notes', 'pages_panel_empty',
  'cd_pages_panel_toggle', 'cd_pages_panel_close']) {
  check(strBase.includes(`"name": "${name}"`), `base locale defines ${name}`);
  check(strZh.includes(`"name": "${name}"`), `zh_CN locale defines ${name}`);
}

console.log(`D05_ORIGINAL_PAGE_OVERVIEW_REPLAY_OK TOTAL=${total} FAILED=0`);
