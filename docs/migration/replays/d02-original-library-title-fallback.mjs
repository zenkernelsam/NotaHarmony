// Phase 739 — 库卡片空标题兜底（e5j.h）+ 回收站副标题（bib/nhb）对齐
// 证据：e5j.h null→default_note_title（b5j/cti/m5j 三消费点），
// bib 回收站行 note_deleted_at + z5c.n；Harmony 卡片兜底 +
// recently_deleted_meta 收窄为单参 medium 日期。
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

const adrP = 'docs/migration/adr/ADR-0687-original-title-fallback.md';
const evP = 'docs/migration/evidence/original-library-title-fallback-jadx-2026-09-25.md';
const rpP = 'docs/migration/reports/phase-739-original-library-title-fallback.md';
check('ADR-0687 存在', fs.existsSync(R(adrP)));
check('证据文档存在', fs.existsSync(R(evP)));
check('Phase 739 报告存在', fs.existsSync(R(rpP)));

const adr = read(adrP);
const ev = read(evP);

// —— 原版 JADX 证据 ——
const e5j = fs.readFileSync(path.join(ORIG, 'defpackage/e5j.java'), 'utf8');
check('e5j.h null→default_note_title',
  /if \(str == null\)[\s\S]*?default_note_title/.test(e5j));
check('e5j.h 非空原样返回', e5j.includes('return str;'));

for (const c of ['b5j', 'cti', 'm5j']) {
  const src = fs.readFileSync(path.join(ORIG, `defpackage/${c}.java`), 'utf8');
  check(`${c} 卡片调用 e5j.h(w09.d)`, src.includes('e5j.h(w09Var'));
}
const y5j = fs.readFileSync(path.join(ORIG, 'defpackage/y5j.java'), 'utf8');
check('y5j 空串也兜底（null || length()==0）',
  y5j.includes('strL.length() == 0') && y5j.includes('default_note_title'));

for (const c of ['nti', 'ksh']) {
  const src = fs.readFileSync(path.join(ORIG, `defpackage/${c}.java`), 'utf8');
  check(`${c} 组件订阅源走 default_note_title`, src.includes('default_note_title'));
}

const bib = fs.readFileSync(path.join(ORIG, 'defpackage/bib.java'), 'utf8');
check('bib 行标题 null→default_note_title',
  bib.includes('strL != null ? new gvd(strL) : new bxb(R.string.data_library_state__default_note_title'));
check('bib 副标题 = note_deleted_at + z5c.n',
  bib.includes('R.string.feature_settings__note_deleted_at') &&
  bib.includes('z5c.n(j)'));

const origStrings = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml', 'utf8');
check('原版 note_deleted_at = "Deleted %1$s"',
  origStrings.includes('feature_settings__note_deleted_at">Deleted %1$s'));
check('原版无 days-left 文案', !/days_left|days left/i.test(origStrings));

// —— Harmony 实现 ——
const page = read('note/src/main/ets/ui/library/LibraryPage.ets');
check('两处库卡片标题带 e5j.h 等价兜底',
  (page.match(/Text\(note\.title\.length > 0 \? note\.title : \$r\('app\.string\.untitled_note'\)\)/g) || []).length === 2);
check('库卡片不再有裸 Text(note.title)', !/Text\(note\.title\)\s*$/m.test(page));

for (const w of ['noteformability/pages/FolderNotesCard.ets',
  'noteformability/pages/RecentNotesCard.ets',
  'noteformability/pages/NoteThumbnailEditPage.ets']) {
  const src = read(`note/src/main/ets/${w}`);
  check(`${w} 组件空题兜底`,
    src.includes("$r('app.string.untitled_note')") &&
    /\.title\.length > 0 \?/.test(src));
}

const trash = read('note/src/main/ets/ui/settings/RecentlyDeletedPage.ets');
check('回收站副标题 Intl medium 日期',
  /formatDeletedTime[\s\S]*?Intl\.DateTimeFormat\(undefined,[\s\S]*?dateStyle: 'medium'/.test(trash));
check('回收站副标题单参调用',
  trash.includes("$r('app.string.recently_deleted_meta',\n            this.formatDeletedTime(note))"));
check('daysLeft 死代码已移除', !trash.includes('daysLeft'));
check('MS_PER_DAY 死常量已移除', !trash.includes('MS_PER_DAY'));
check('ISO 拼接已移除',
  !trash.includes('`${date.getFullYear()}-${month}-${day}`'));
check('回收站行标题空题兜底仍在',
  trash.includes("note.title.length > 0 ? note.title : $r('app.string.untitled_note')"));

const en = read('note/src/main/resources/base/element/string.json');
const zh = read('note/src/main/resources/zh_CN/element/string.json');
check('en recently_deleted_meta = "Deleted %s"',
  /"recently_deleted_meta"[\s\S]*?"Deleted %s"/.test(en));
check('zh recently_deleted_meta = "删除于 %s"',
  zh.includes('"recently_deleted_meta", "value": "删除于 %s"'));
check('en 无 days-left 段', !/days left/.test(en));

// —— 文档钉 ——
check('ADR 引证 e5j.h', adr.includes('e5j.h'));
check('ADR 引证 bib', adr.includes('bib'));
check('证据含 y5j 空串证据', ev.includes('y5j.java'));
check('证据含 bib/nhb 回收站行', ev.includes('bib.java') && ev.includes('nhb'));

check('修复总纲登记 Phase 739', read('docs/migration/audit-2026-08/修复总纲.md').includes('Phase 739'));
check('修复总纲2 登记 Phase 739', read('docs/migration/audit-2026-08/修复总纲2.md').includes('Phase 739'));
check('进展文档登记 Phase 739', read('docs/migration/reports/修复进展-2026-08-09.md').includes('Phase 739'));

console.log(`D02_ORIGINAL_LIBRARY_TITLE_FALLBACK_REPLAY_OK TOTAL=${total} FAILED=${failed}`);
process.exit(failed === 0 ? 0 : 1);
