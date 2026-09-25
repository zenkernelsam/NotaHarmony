// Phase 740 — 导入详情页确认钮上下文文案（y5j.a add_to_note/
// create_single_note/create_new_note）对齐
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

const adrP = 'docs/migration/adr/ADR-0688-original-import-confirm-label.md';
const evP = 'docs/migration/evidence/original-import-confirm-label-jadx-2026-09-25.md';
const rpP = 'docs/migration/reports/phase-740-original-import-confirm-label.md';
check('ADR-0688 存在', fs.existsSync(R(adrP)));
check('证据文档存在', fs.existsSync(R(evP)));
check('Phase 740 报告存在', fs.existsSync(R(rpP)));

const adr = read(adrP);
const ev = read(evP);

// —— 原版 JADX 证据 ——
const y5j = fs.readFileSync(path.join(ORIG, 'defpackage/y5j.java'), 'utf8');
check('y5j 空题→default_note_title',
  y5j.includes('strL == null || strL.length() == 0') &&
  y5j.includes('data_library_state__default_note_title'));
check('y5j 确认钮 = add_to_note',
  y5j.includes('R.string.ui_fileimport__add_to_note'));
check('y5j 分支 create_single/create_new + loading/existing',
  y5j.includes('ui_fileimport__create_single_note') &&
  y5j.includes('ui_fileimport__create_new_note') &&
  y5j.includes('ui_fileimport__loading') &&
  y5j.includes('ui_fileimport__add_to_existing_note'));

const strings = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml', 'utf8');
check('原版 add_to_note 文案', strings.includes('add_to_note">Add to \\"%1$s\\"'));
check('原版 create_single_note 文案', strings.includes('create_single_note">Create single note'));
check('原版 create_new_note 文案', strings.includes('create_new_note">Create new note'));

// —— Harmony 实现 ——
const sheet = read('note/src/main/ets/ui/components/ImportDetailsSheet.ets');
check('confirmLabel 方法存在', sheet.includes('private confirmLabel(): ResourceStr'));
check('确认钮改用 confirmLabel()', sheet.includes('Button(this.confirmLabel())'));
check('EXISTING → import_add_to_note',
  /EXISTING_NOTE[\s\S]*?import_add_to_note/.test(sheet));
check('SINGLE/SEPARATE → create_single/create_new',
  sheet.includes('import_create_single') && sheet.includes('import_create_new'));
check('空题 getStringSync(untitled_note) 兜底',
  sheet.includes("getStringSync($r('app.string.untitled_note').id)"));
check('不再用静态 import_confirm 绑钮',
  !sheet.includes("Button($r('app.string.import_confirm'))"));

const en = read('note/src/main/resources/base/element/string.json');
const zh = read('note/src/main/resources/zh_CN/element/string.json');
check('en import_add_to_note', en.includes('"import_add_to_note", "value": "Add to \\"%s\\""'));
check('en import_create_single', en.includes('"import_create_single", "value": "Create single note"'));
check('en import_create_new', en.includes('"import_create_new", "value": "Create new note"'));
check('zh import_add_to_note', zh.includes('"import_add_to_note", "value": "添加到“%s”"'));
check('zh import_create_single', zh.includes('"import_create_single", "value": "创建单个笔记"'));
check('zh import_create_new', zh.includes('"import_create_new", "value": "创建新笔记"'));
check('import_confirm 键保留', en.includes('"import_confirm"'));

// —— 文档钉 ——
check('ADR 引证 y5j', adr.includes('y5j'));
check('ADR 引证 add_to_note', adr.includes('add_to_note'));
check('ADR 记录未选态偏差', adr.includes('importEnabled'));
check('证据含语义映射', ev.includes('EXISTING_NOTE'));
check('证据含原版文案', ev.includes('Add to'));

check('修复总纲登记 Phase 740', read('docs/migration/audit-2026-08/修复总纲.md').includes('Phase 740'));
check('修复总纲2 登记 Phase 740', read('docs/migration/audit-2026-08/修复总纲2.md').includes('Phase 740'));
check('进展文档登记 Phase 740', read('docs/migration/reports/修复进展-2026-08-09.md').includes('Phase 740'));

console.log(`D02_ORIGINAL_IMPORT_CONFIRM_LABEL_REPLAY_OK TOTAL=${total} FAILED=${failed}`);
process.exit(failed === 0 ? 0 : 1);
