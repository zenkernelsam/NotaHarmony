// Phase 721 — app__ 族尾部收口（快捷方式标签 + 共享打开 500MB 上限 + 平台边界登记）
// 原版证据：jv5.f flag16 → 524288000；vs8 → gr9 分类映射；
//   app__shortcut_* 静态标签；update_*/app_rating_*/kbd_shortcut_* 平台项。
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

// === 快捷方式标签（与原版 app__shortcut_* 逐字对齐）===
check('en shortcut_new_note = New Note',
  stringsEn.includes('"shortcut_new_note", "value": "New Note"'));
check('en shortcut_new_photo = New Photo',
  stringsEn.includes('"shortcut_new_photo", "value": "New Photo"'));
check('zh shortcut_new_photo 跟随原版语义',
  stringsZh.includes('"shortcut_new_photo", "value": "新建照片"'));

// === 共享打开大小上限（jv5.f flag16 → 524288000）===
check('ImportResult.TOO_LARGE 枚举存在',
  /TOO_LARGE\s*=\s*5/.test(importer));
check('SHARED_OPEN_MAX_BYTES = 524288000',
  importer.includes('SHARED_OPEN_MAX_BYTES: number = 524288000'));
check('importSharedUris 预检 statSync+上限',
  /importSharedUris\([\s\S]*?fileIo\.statSync\(uri\)\.size[\s\S]*?SHARED_OPEN_MAX_BYTES/.test(importer));
check('超限早退 TOO_LARGE',
  /size > SHARED_OPEN_MAX_BYTES[\s\S]*?result: ImportResult\.TOO_LARGE/.test(importer));

// === 打开失败分类提示（vs8 → app__open_pdf_*）===
check('en open_pdf_too_large',
  stringsEn.includes('"open_pdf_too_large", "value": "This PDF is too large to import"'));
check('en open_pdf_failed',
  stringsEn.includes('open_pdf_failed'));
check('zh open_pdf_too_large',
  stringsZh.includes('"open_pdf_too_large", "value": "PDF 过大，无法导入"'));
check('zh open_pdf_failed',
  stringsZh.includes('"open_pdf_failed", "value": "无法打开此 PDF"'));
check('共享打开失败映射 TOO_LARGE→open_pdf_too_large',
  /result === ImportResult\.TOO_LARGE \?\s*\$r\('app\.string\.open_pdf_too_large'\)\s*:\s*\$r\('app\.string\.open_pdf_failed'\)/.test(library));
check('CANCELLED 仍静默',
  /report\.result !== ImportResult\.CANCELLED[\s\S]{0,400}?open_pdf_failed/.test(library));

// === 平台边界登记（ADR-0669）===
const adr = read('docs/migration/adr/ADR-0669-original-app-tail.md');
check('ADR-0669 存在', adr.length > 500);
check('ADR 覆盖 update/in-app-review 边界', /update_|app_rating|in-app/i.test(adr));
check('ADR 覆盖键盘快捷键组边界', /kbd_shortcut|shortcut group/i.test(adr));
check('ADR 覆盖新窗口边界', /new_window|多窗口/i.test(adr));
check('ADR 覆盖 native 库缺失边界', /missing_native_library|\.so/i.test(adr));
check('ADR 覆盖动态快捷方式边界', /shortcut_recent_note_long|动态快捷方式/i.test(adr));
check('ADR 覆盖 login_required_for_photo', /login_required_for_photo/.test(adr));
check('ADR 覆盖 note_limit_share', /note_limit_share/.test(adr));
check('ADR 覆盖 account_deletion_notice', /account_deletion/.test(adr));
check('ADR 记录密码提示为超集偏差', /password/i.test(adr) && /prompt|提示输入|交互/i.test(adr));

const evidence = read('docs/migration/evidence/original-app-tail-jadx-2026-09-25.md');
check('证据文档存在', evidence.length > 500);
check('证据引用 jv5 524288000', evidence.includes('524288000'));
check('证据引用 vs8 状态映射', /vs8/.test(evidence));
check('证据引用快捷方式原文', evidence.includes('app__shortcut_new_photo'));

const report = read('docs/migration/reports/phase-721-original-app-tail.md');
check('中文报告存在', report.length > 500);
check('报告引用原版证据', /jv5|vs8|shortcut/.test(report));

// === 反向针：防回归 ===
check('generic 1GB 上限仍保留（非共享路径）',
  importer.includes('ZIP_MAX_ARCHIVE_BYTES'));
check('密码提示流程未移除',
  library.includes('pdfPasswordPrompt'));

console.log(`D02_ORIGINAL_APP_TAIL_REPLAY_OK TOTAL=${total} FAILED=${failed}`);
process.exit(failed === 0 ? 0 : 1);
