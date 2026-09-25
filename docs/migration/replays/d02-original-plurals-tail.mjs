// Phase 725 — plurals.xml 尾部收口（PDF 10000 页截断提示 + 多删标题复数化 +
//   导入清单文件计数 + 其余复数族边界登记）
// 原版证据：fr1:113 min(pageCount,10000) 截断 + truncated 标记；
//   i8 case4 → feature_library__delete_note_message（one/other 标题）；
//   aeh:87 → ui_fileimport__n_files_capitalized；
//   bib → feature_settings__delete_confirmation_message / notes_selected；
//   vs8 → ui_fileimport__pdfs_truncated。
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

const stringsEn = read('note/src/main/resources/base/element/string.json');
const stringsZh = read('note/src/main/resources/zh_CN/element/string.json');
const importer = read(`${SRC}/data/NoteImporter.ets`);
const library = read(`${SRC}/ui/library/LibraryPage.ets`);
const sheet = read(`${SRC}/ui/components/ImportDetailsSheet.ets`);

// === PDF 10000 页截断（fr1:113）===
check('PDF_IMPORT_MAX_PAGES 常量保留',
  importer.includes('PDF_IMPORT_MAX_PAGES: number = 10000'));
check('超上限不再抛错而是截断',
  /rawPageCount > PDF_IMPORT_MAX_PAGES \? PDF_IMPORT_MAX_PAGES : 0/.test(importer));
check('截断后循环按导入页数遍历',
  /truncatedPages > 0 \? truncatedPages : rawPageCount[\s\S]{0,200}?index < pageCount/.test(importer));
check('页数下界校验保留',
  /rawPageCount <= 0[\s\S]{0,120}?out of bounds/.test(importer));
check('ImportedPdfParse 携带 truncatedPages',
  /interface ImportedPdfParse \{[\s\S]*?truncatedPages: number/.test(importer));
check('StagedPdfParse 携带 truncatedPages',
  /interface StagedPdfParse \{[\s\S]*?truncatedPages: number/.test(importer));
check('stageAndParse 透传 parse.truncatedPages',
  importer.includes('truncatedPages: parse.truncatedPages'));
check('成功报告带截断元数据（独立导入）',
  /truncatedPages: staged\.truncatedPages[\s\S]{0,120}?truncatedCount: staged\.truncatedPages > 0 \? 1 : 0/.test(importer));
check('聚合报告累计 truncatedCount',
  /let truncatedCount: number = 0[\s\S]*?truncatedCount \+=/.test(importer));
check('聚合报告回填 truncatedPages=上限',
  /truncatedPages: truncatedCount > 0 \? PDF_IMPORT_MAX_PAGES : 0/.test(importer));

// === ui_fileimport__pdfs_truncated 提示 ===
check('en import_pdf_truncated_one 原文',
  stringsEn.includes('"import_pdf_truncated_one", "value": "PDF was too long. Imported the first %d pages."'));
check('en import_pdfs_truncated_other 原文',
  stringsEn.includes('"import_pdfs_truncated_other", "value": "Some PDFs were too long. Imported the first %d pages of each."'));
check('zh import_pdf_truncated_one',
  stringsZh.includes('"import_pdf_truncated_one", "value": "PDF 过长，仅导入了前 %d 页"'));
check('zh import_pdfs_truncated_other',
  stringsZh.includes('"import_pdfs_truncated_other", "value": "部分 PDF 过长，各导入了前 %d 页"'));
check('toastTruncatedPages 复数分流',
  /toastTruncatedPages\(report[\s\S]*?count > 1 \?[\s\S]*?import_pdfs_truncated_other[\s\S]*?import_pdf_truncated_one/.test(library));
check('共享打开路径挂截断提示',
  /importSharedAndOpen[\s\S]*?this\.toastTruncatedPages\(report\)/.test(library));
check('文件选取路径挂截断提示',
  /importAndOpen[\s\S]*?this\.toastTruncatedPages\(report\)/.test(library));

// === feature_library__delete_note_message 复数化 ===
check('en delete_note_title_one = Delete Note?',
  stringsEn.includes('"delete_note_title_one", "value": "Delete Note?"'));
check('en delete_notes_title_other = Delete Notes?',
  stringsEn.includes('"delete_notes_title_other", "value": "Delete Notes?"'));
check('en delete_notes_message_one 单数语法',
  stringsEn.includes('"delete_notes_message_one", "value": "Move %d note to Recently Deleted? You can recover it within 30 days."'));
check('zh 删除标题两形态存在',
  stringsZh.includes('"delete_note_title_one"') && stringsZh.includes('"delete_notes_title_other"'));
check('多删对话框标题复数化',
  /title: count === 1 \? \$r\('app\.string\.delete_note_title_one'\)\s*:\s*\$r\('app\.string\.delete_notes_title_other'\)/.test(library));
check('多删对话框消息复数化',
  /count === 1 \?\s*\$r\('app\.string\.delete_notes_message_one', count\)\s*:\s*\$r\('app\.string\.delete_notes_message', count\)/.test(library));

// === ui_fileimport__n_files_capitalized 计数标题 ===
check('en import_files_count_one = %d File',
  stringsEn.includes('"import_files_count_one", "value": "%d File"'));
check('en import_files_count_other = %d Files',
  stringsEn.includes('"import_files_count_other", "value": "%d Files"'));
check('zh import_files_count 两形态',
  stringsZh.includes('"import_files_count_one"') && stringsZh.includes('"import_files_count_other"'));
check('导入清单计数随数量复数化',
  /orderedFiles\.length === 1 \?[\s\S]*?import_files_count_one[\s\S]*?import_files_count_other/.test(sheet));

// === 反向针：既有行为不回归 ===
check('共享打开 500MB 上限仍保留',
  importer.includes('SHARED_OPEN_MAX_BYTES: number = 524288000'));
check('密码提示流程未移除',
  importer.includes('PARSE_ERROR_PASSWORD'));
check('导入清单排列模式保留',
  sheet.includes('this.arranging = !this.arranging'));

// === 边界登记（ADR-0673）===
const adr = read('docs/migration/adr/ADR-0673-original-plurals-tail.md');
check('ADR-0673 存在', adr.length > 500);
check('ADR 覆盖 PDF 截断决策', /fr1|10000|pdfs_truncated/.test(adr));
check('ADR 覆盖 delete_note_message 复数', /delete_note_message/.test(adr));
check('ADR 登记 recently-deleted 多选缺口',
  /delete_confirmation_message|bib/.test(adr));
check('ADR 登记 version_history 复数',
  /version_history/.test(adr));
check('ADR 登记 paywall footnote 边界',
  /free_trial_footnote|paywall/.test(adr));
check('ADR 登记 selected_files / ntb 边界',
  /selected_files|ntb_files_could_not_be_imported/.test(adr));

const evidence = read('docs/migration/evidence/original-plurals-tail-jadx-2026-09-25.md');
check('证据文档存在', evidence.length > 400);
check('证据引用 fr1 截断代码', /fr1|10000/.test(evidence));
check('证据引用 i8 case4', /i8/.test(evidence));
check('证据引用 bib', /bib/.test(evidence));

const report = read('docs/migration/reports/phase-725-original-plurals-tail.md');
check('中文报告存在', report.length > 500);
check('报告引用原版证据', /fr1|plurals|pdfs_truncated/.test(report));

console.log(`D02_ORIGINAL_PLURALS_TAIL_REPLAY_OK TOTAL=${total} FAILED=${failed}`);
process.exit(failed === 0 ? 0 : 1);
