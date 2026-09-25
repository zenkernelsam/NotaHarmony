// Phase 723 — feature_library__ 族尾部收口（审计闭合登记）
// 原版证据：md.java（侧栏 swipe a11y）、m8/h3/ccj（ROLE_NOTES 提示）、
//   n32/elc（未索引诊断）、排序/搜索/空态资源矩阵。
import fs from 'node:fs';
import path from 'node:path';

const REPO = path.resolve(process.cwd());
const SRC = 'note/src/main/ets';
const R = (p) => path.join(REPO, p);
const read = (p) => fs.readFileSync(R(p), 'utf8');

let total = 0, failed = 0;
const check = (name, cond) => {
  total++;
  if (!cond) { failed++; console.log(`  FAIL ${name}`); }
};

const strings = read('note/src/main/resources/base/element/string.json');
const library = read(`${SRC}/ui/library/LibraryPage.ets`);

// === 已移植锚点：排序/搜索/空态/未索引 ===
check('sort 资源矩阵在场',
  ['sort_a_to_z', 'sort_oldest_to_newest', 'sort_newest_to_oldest']
    .every((k) => strings.includes(`"${k}"`)));
check('search_in_folder + search_show_all_notes',
  strings.includes('search_in_folder') && strings.includes('search_show_all_notes'));
check('空态三族资源在场',
  ['empty_favorite_notes_title', 'empty_recent_notes_title',
    'empty_unfiled_notes_title', 'empty_folder_body',
    'empty_folder_with_children_body', 'lets_get_started']
    .every((k) => strings.includes(`"${k}"`)));
check('搜索空态 no_matching_notes',
  strings.includes('no_matching_notes'));
check('unindexed 资源族在场',
  ['unindexed_notes', 'unindexed_notes_count', 'unindexed_explainer']
    .every((k) => strings.includes(`"${k}"`)));
check('LibraryPage unindexedDialog 在场',
  library.includes('unindexedDialog'));
check('copy_note_id + show_in_folder',
  strings.includes('copy_note_id') && strings.includes('show_in_folder'));
check('scanned_document_title 逐字一致',
  strings.includes('"scanned_document_title", "value": "Scanned Document %1$s"'));
check('expand/collapse_folder 资源在场',
  strings.includes('expand_folder') && strings.includes('collapse_folder'));
check('文件夹展开状态机在场',
  library.includes('expandedFolderIds'));

// === 边界项引用既有登记 ===
const adr0661 = read('docs/migration/adr/ADR-0661-original-onboarding-sibling-keys-failclosed.md');
check('notes_role_* 已由 ADR-0661 登记', /notes_role/.test(adr0661));
const adr0652 = fs.existsSync(R('docs/migration/adr/ADR-0652-original-learn-ai-surface-failclosed.md')) ?
  read('docs/migration/adr/ADR-0652-original-learn-ai-surface-failclosed.md') : '';
check('learn_* 已由 ADR-0652 登记', adr0652.length > 300);
const adr0658 = fs.existsSync(R('docs/migration/adr/ADR-0658-original-remote-flag-tail-failclosed.md')) ?
  read('docs/migration/adr/ADR-0658-original-remote-flag-tail-failclosed.md') : '';
check('home_* 旗标态已登记', adr0658.length > 300);
check('open_in_new_window/report_note 已登记不可移植',
  /open_in_new_window.*report_note|not portable/i.test(library) ||
  /open_in_new_window/i.test(adr0658));

// === ADR-0671 本体 ===
const adr = read('docs/migration/adr/ADR-0671-original-feature-library-tail.md');
check('ADR-0671 存在', adr.length > 500);
check('ADR 覆盖排序矩阵', /A_to_Z|sort/.test(adr));
check('ADR 覆盖空态族', /empty_favorite_notes|空态/.test(adr));
check('ADR 覆盖侧栏', /sidebar_/.test(adr));
check('ADR 覆盖未索引诊断', /unindexed|未索引/.test(adr));
check('ADR 覆盖 home_* 边界', /home_|LIBRARY_HOME/.test(adr));
check('ADR 覆盖 notes_role 边界', /notes_role|ROLE_NOTES/.test(adr));
check('ADR 覆盖扫描件', /docscan|scanned_document/.test(adr));
check('ADR 声明族闭合', /98 键/.test(adr));

// === 证据 + 报告 ===
const evidence = read('docs/migration/evidence/original-feature-library-tail-jadx-2026-09-25.md');
check('证据文档存在', evidence.length > 500);
check('证据引用 md.java swipe', /md\.java|swipe_action/.test(evidence));
check('证据引用 notes_role 类', /m8|h3|ccj/.test(evidence));

const report = read('docs/migration/reports/phase-723-original-feature-library-tail.md');
check('中文报告存在', report.length > 500);
check('报告声明族闭合', /feature_library/.test(report) && /闭合|收口/.test(report));

// === 反向针 ===
check('delete/rename 对话框仍在场',
  library.includes('delete_folder_message') && library.includes('rename'));
check('LibrarySection 分区在场', library.includes('LibrarySection.FAVORITES'));

console.log(`D02_ORIGINAL_FEATURE_LIBRARY_TAIL_REPLAY_OK TOTAL=${total} FAILED=${failed}`);
process.exit(failed === 0 ? 0 : 1);
