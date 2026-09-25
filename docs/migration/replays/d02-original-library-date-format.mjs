// Phase 738 — 库卡片日期格式对齐（z5c.n → ofLocalizedDate(MEDIUM)）
// 证据：z5c.n + x2f(0) + nk9/ok9/mk9 卡片模型构造点；Harmony 改用
// Intl.DateTimeFormat dateStyle:'medium'，扫描标题用 date+time。
import fs from 'node:fs';
import path from 'node:path';

const REPO = path.resolve(process.cwd());
const ORIG = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources';
const R = (p) => path.join(REPO, p);
const read = (p) => fs.readFileSync(R(p), 'utf8');

let total = 0, failed = 0;
const check = (name, cond) => {
  total++;
  if (!cond) { failed++; console.log('FAIL', name); }
};

const adrP = 'docs/migration/adr/ADR-0686-original-library-date-format.md';
const evP = 'docs/migration/evidence/original-library-date-format-jadx-2026-09-25.md';
const rpP = 'docs/migration/reports/phase-738-original-library-date-format.md';
check('ADR-0686 存在', fs.existsSync(R(adrP)));
check('证据文档存在', fs.existsSync(R(evP)));
check('Phase 738 报告存在', fs.existsSync(R(rpP)));

const adr = read(adrP);
const ev = read(evP);

// —— 原版 JADX 证据 ——
const z5c = fs.readFileSync(path.join(ORIG, 'defpackage/z5c.java'), 'utf8');
check('z5c.n = h.format(Instant.ofEpochMilli)',
  z5c.includes('public static final String n(long j2)'));
check('z5c.n 用 h（MEDIUM 日期懒实例）',
  /String str = h\.a\(\)\.format\(Instant\.ofEpochMilli\(j2\)\)/.test(z5c));
check('z5c.h = x2f(0)', z5c.includes('new zi(new x2f(0))'));
check('z5c.i = x2f(1)', z5c.includes('new zi(new x2f(1))'));
check('z5c.j = x2f(2)', z5c.includes('new zi(new x2f(2))'));

const x2f = fs.readFileSync(path.join(ORIG, 'defpackage/x2f.java'), 'utf8');
check('x2f case0 = ofLocalizedDate(MEDIUM)',
  x2f.includes('DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM)'));
check('x2f case1 = ofLocalizedTime(SHORT)',
  x2f.includes('DateTimeFormatter.ofLocalizedTime(FormatStyle.SHORT)'));
check('x2f case2 = ofLocalizedDateTime(MEDIUM,SHORT)',
  x2f.includes('DateTimeFormatter.ofLocalizedDateTime(FormatStyle.MEDIUM, FormatStyle.SHORT)'));

const nk9 = fs.readFileSync(path.join(ORIG, 'defpackage/nk9.java'), 'utf8');
const ok9 = fs.readFileSync(path.join(ORIG, 'defpackage/ok9.java'), 'utf8');
const mk9 = fs.readFileSync(path.join(ORIG, 'defpackage/mk9.java'), 'utf8');
check('nk9 卡片 e 字段 = z5c.n', nk9.includes('z5c.n(j89Var.m())'));
check('ok9 卡片 e 字段 = z5c.n', ok9.includes('z5c.n(j89Var.m())'));
check('mk9 卡片 e 字段 = z5c.n', mk9.includes('z5c.n(') &&
  mk9.includes('new w09('));

// —— Harmony 实现 ——
const page = read('note/src/main/ets/ui/library/LibraryPage.ets');
check('卡片副标题改用 formatLibraryDate（两处）',
  (page.match(/formatLibraryDate\(this\.currentFolderId === null/g) || []).length === 2);
check('formatLibraryDate 用 Intl.DateTimeFormat medium',
  /formatLibraryDate[\s\S]*?Intl\.DateTimeFormat\(undefined,[\s\S]*?dateStyle: 'medium'/.test(page));
check('formatLibraryDateTime 用 medium+short',
  /formatLibraryDateTime[\s\S]*?dateStyle: 'medium', timeStyle: 'short'/.test(page));
check('扫描标题用 formatLibraryDateTime',
  page.includes('this.formatLibraryDateTime(Date.now())'));
check('旧的 M/D H:MM 拼接已移除',
  !page.includes("d.getMonth() + 1 + '/' + d.getDate() + ' ' + d.getHours()"));
check('字段选择规则保留（lastOpened/updatedAt）',
  (page.match(/note\.lastOpened : note\.updatedAt/g) || []).length === 2);
check('Intl 调用带兜底',
  /catch \(_error\)/.test(page));

// —— 文档钉 ——
check('ADR 引证 z5c.n', adr.includes('z5c.n'));
check('ADR 引证 ofLocalizedDate(MEDIUM)', adr.includes('ofLocalizedDate'));
check('ADR 记录扫描标题近似', adr.includes('z5c.j'));
check('证据含 mk9/nk9/ok9', ev.includes('nk9.java') && ev.includes('ok9.java') && ev.includes('mk9.java'));
check('证据排除伪候选', ev.includes('ypd') && ev.includes('zaj'));

// —— 运行时等价模型 ——
const ts = new Date(2026, 0, 5, 14, 30).getTime();
const enFmt = new Intl.DateTimeFormat('en-US', { dateStyle: 'medium' }).format(new Date(ts));
check('en-US medium 示例形态 "Jan 5, 2026"',
  /^[A-Z][a-z]{2} \d{1,2}, \d{4}$/.test(enFmt));
const dtFmt = new Intl.DateTimeFormat('en-US',
  { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(ts));
check('en-US medium+short 含日期与时间',
  dtFmt.includes('2026') && /\d{1,2}:\d{2}/.test(dtFmt));

check('修复总纲登记 Phase 738', read('docs/migration/audit-2026-08/修复总纲.md').includes('Phase 738'));
check('修复总纲2 登记 Phase 738', read('docs/migration/audit-2026-08/修复总纲2.md').includes('Phase 738'));
check('进展文档登记 Phase 738', read('docs/migration/reports/修复进展-2026-08-09.md').includes('Phase 738'));

console.log(`D02_ORIGINAL_LIBRARY_DATE_FORMAT_REPLAY_OK TOTAL=${total} FAILED=${failed}`);
process.exit(failed === 0 ? 0 : 1);
