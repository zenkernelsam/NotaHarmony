// Phase 1423 — 原版 Unindexed Notes 管理对话框移植
// 证据链（decompiled_1.4.2）：
//   zsb.java :1180-1200 —— 横幅 Learn More → o(rgaVar4) && whf.b 非空 &&
//     whf.c 空时打开 l8n.h；初始选集 = hashSet.add(w9b.a(q0b.a)) 全部 id。
//   l8n.java h(...) —— m8n.a 对话框承载 p6f(function0,list,bz5,set) 内容。
//   p6f.java case15 —— 列表（nlh LazyColumn + uq5 case8 行）+ 底栏：
//     Select All/Deselect All（z3 全真时 deselect_all）+ "N notes
//     selected"（feature_library__notes_selected 复数）+ g8n.a 按钮盒。
//   uq5.java case8 -> l8n.g —— 92dp 行：checkmark_circle /
//     circle_empty_med_outline 图标（z 选中态）+ q0b.g 标题 +
//     qbn.h(q0b.d) 日期副题，feature_library__select_note cd。
//   y73.java default —— Close（o9n.a）+ Index Notes（f8n.a + ubm.b =
//     ig2(5) = feature_library__index_notes 文案），enabled = 选集非空。
//   z73.java default —— Index Notes onClick：bz5(selection→list) =
//     dsb 重建协程（psb）后 function0() = dismiss。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/defpackage';
const R = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res';
const H = 'C:/HarmonyProject/NotaHarmony/note/src/main';

const checks = [];
const check = (name, cond) => {
  assert.equal(cond, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const zsb = fs.readFileSync(`${S}/zsb.java`, 'utf8');
const l8n = fs.readFileSync(`${S}/l8n.java`, 'utf8');
const p6f = fs.readFileSync(`${S}/p6f.java`, 'utf8');
const uq5 = fs.readFileSync(`${S}/uq5.java`, 'utf8');
const y73 = fs.readFileSync(`${S}/y73.java`, 'utf8');
const z73 = fs.readFileSync(`${S}/z73.java`, 'utf8');
const ig2 = fs.readFileSync(`${S}/ig2.java`, 'utf8');
const strings = fs.readFileSync(`${R}/values/strings.xml`, 'utf8');
const plurals = fs.readFileSync(`${R}/values/plurals.xml`, 'utf8');

const page = fs.readFileSync(`${H}/ets/ui/library/LibraryPage.ets`, 'utf8');
const viewModel = fs.readFileSync(`${H}/ets/ui/library/LibraryViewModel.ets`, 'utf8');
const repo = fs.readFileSync(`${H}/ets/data/NoteRepositoryImpl.ets`, 'utf8');
const iface = fs.readFileSync(`${H}/ets/data/RepositoryInterfaces.ets`, 'utf8');
const stroke = fs.readFileSync(`${H}/ets/data/StrokePersistence.ets`, 'utf8');
const en = fs.readFileSync(`${H}/resources/base/element/string.json`, 'utf8');
const zh = fs.readFileSync(`${H}/resources/zh_CN/element/string.json`, 'utf8');

// ---- 原版锚点 ----
check('原版 l8n.h = m8n.a 对话框承载 p6f 选择内容',
  /m8n\.a\(function1, new v24\(7[^)]*\), k31\.L\(702148955, new p6f\(function0, list, bz5Var, set\)/.test(l8n));
check('原版 zsb 初始选集 = 全部 id（hashSet.add）',
  /hashSet\.add\(w9b\.a\(\(\(q0b\)/.test(zsb));
check('原版 zsb 打开条件 = whf.b 非空 && whf.c 空',
  /whfVar\.b\.isEmpty\(\) \|\| !whfVar\.c\.isEmpty\(\)/.test(zsb));
check('原版 p6f case15 底栏 Deselect All/Select All 切换',
  /R\.string\.feature_library__deselect_all/.test(p6f));
check('原版 p6f case15 计数 = notes_selected 复数',
  /R\.plurals\.feature_library__notes_selected/.test(p6f));
check('原版 uq5 case8 行 = l8n.g 选中态渲染',
  /l8n\.g\(null, q0bVar, zC/.test(uq5));
check('原版 l8n.g 行图标 = checkmark_circle/circle_empty_med_outline',
  /checkmark_circle/.test(l8n) && /circle_empty_med_outline/.test(l8n));
check('原版 l8n.g 行 cd = feature_library__select_note',
  /R\.string\.feature_library__select_note/.test(l8n));
check('原版 y73 按钮对 = Close + Index Notes（ubm.b）',
  /ui_designsystem__close/.test(y73) && /ubm\.b/.test(y73));
check('原版 ig2(5) = feature_library__index_notes 文案',
  /feature_library__index_notes/.test(ig2));
check('原版 z73 = bz5(selection) 后 function0() dismiss',
  /bz5Var\.invoke\(e52\.i4\(\(Set\)/.test(z73) && /function0\.invoke\(\)/.test(z73));
check('原版资源：index_notes/select_all/deselect_all/select_note',
  /name="feature_library__index_notes">Index Notes</.test(strings) &&
  /name="feature_library__select_all">Select All</.test(strings) &&
  /name="feature_library__deselect_all">Deselect All</.test(strings) &&
  /name="feature_library__select_note">Select Note</.test(strings));
check('原版资源：notes_selected 复数条',
  /name="feature_library__notes_selected"[\s\S]{0,200}quantity="other"/.test(plurals));

// ---- Harmony 实现锚点 ----
check('Harmony 仓储接口声明 getUnindexedNotes/reindexUnindexedNotes',
  /getUnindexedNotes\(\): Promise<NoteMeta\[]>/.test(iface) &&
  /reindexUnindexedNotes\(noteIds: string\[\]\): Promise<number>/.test(iface));
check('Harmony getUnindexedNotes = NOT EXISTS search_item 查询',
  /NOT EXISTS \(SELECT 1 FROM search_item item\s*WHERE item\.note_id = note\.id\)/.test(repo));
check('Harmony reindex 重建 TITLE + TEXT_BLOCK（searchTextForElement）',
  /upsertTitleSearchItem\(store, noteId, title\)/.test(repo) &&
  /searchTextForElement\(kind, payload\)/.test(repo) &&
  /SearchItemType\.TEXT_BLOCK/.test(repo));
check('Harmony reindex 写 search_page_state.indexed_revision',
  /search_page_state/.test(repo) && /indexed_revision/.test(repo));
check('Harmony StrokePersistence 导出 searchTextForElement',
  /export function searchTextForElement/.test(stroke));
check('Harmony ViewModel 持有 unindexedNotes 列表',
  /unindexedNotes: NoteMeta\[\]/.test(viewModel));
check('Harmony ViewModel reindexUnindexedNotes 串 mutation 并刷新',
  /async reindexUnindexedNotes\(noteIds/.test(viewModel) &&
  /repo\.reindexUnindexedNotes\(noteIds\)/.test(viewModel) &&
  /repo\.getUnindexedNotes\(\)/.test(viewModel));
check('Harmony 对话框默认全选（aboutToAppear 收集全部 id）',
  /aboutToAppear\(\): void \{[\s\S]{0,220}ids\.push\(note\.id\)/.test(page));
check('Harmony 行 = checkmark_circle/circle_empty + select_note cd',
  /checkmark_circle/.test(page) && /circle_empty_med_outline/.test(page) &&
  /select_note/.test(page));
check('Harmony 底栏 = select_all/deselect_all + notes_selected 复数',
  /'app\.string\.deselect_all'/.test(page) && /'app\.string\.select_all'/.test(page) &&
  /note_selected_singular/.test(page) && /notes_selected/.test(page));
check('Harmony Index Notes 按钮 enabled=选集非空 && !indexing',
  /'app\.string\.index_notes'/.test(page) &&
  /enabled\(this\.selectedIds\.length > 0 && !this\.indexing\)/.test(page));
check('Harmony 按钮对 = Close + Index Notes',
  /'app\.string\.close'[\s\S]{0,600}'app\.string\.index_notes'/.test(page));
check('Harmony 资源 index_notes en+zh',
  /"name": "index_notes",\s*"value": "Index Notes"/.test(en) &&
  /"name": "index_notes", "value": "为笔记编制索引"/.test(zh));

console.log(`\nTOTAL ${checks.length} checks`);
