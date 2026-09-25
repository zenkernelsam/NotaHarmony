// Phase 734 — values 资源族尾项收口
// 证据：arrays/bools/integers/dimens/styles/attrs/public 全量分类登记。
import fs from 'node:fs';
import path from 'node:path';

const REPO = path.resolve(process.cwd());
const R = (p) => path.join(REPO, p);
const read = (p) => fs.readFileSync(R(p), 'utf8');

let total = 0, failed = 0;
const check = (name, cond) => {
  total++;
  if (!cond) { failed++; console.log('FAIL', name); }
};

const adrP = 'docs/migration/adr/ADR-0682-original-values-tail.md';
const evP = 'docs/migration/evidence/original-values-tail-jadx-2026-09-25.md';
const rpP = 'docs/migration/reports/phase-734-original-values-tail.md';
check('ADR-0682 存在', fs.existsSync(R(adrP)));
check('证据文档存在', fs.existsSync(R(evP)));
check('Phase 734 报告存在', fs.existsSync(R(rpP)));

const adr = read(adrP);
const ev = read(evP);

// —— 分类完整性 ——
for (const s of ['arrays', 'bools', 'integers', 'dimens', 'styles', 'attrs', 'public', 'drawables.xml']) {
  check(`证据覆盖 ${s}`, ev.includes(s));
}
check('ADR 记录 SPen swatch 边界', adr.includes('spen_setting_swatch'));
check('ADR 记录 quick_tool 尺寸边界', adr.includes('quick_tool_center') || adr.includes('quick_tool_edge'));
check('ADR 记录夜主题链映射', adr.includes('NightAdjusted.Theme.Nb'));
check('ADR 记录 ThemeStore 对应', adr.includes('ThemeStore'));
check('ADR 记录对话框窗口服饰等价', adr.includes('DialogWindowTheme'));
check('ADR 记录 attrs 编译期语义', adr.includes('declare-styleable'));
check('ADR 记录 public.xml 无语义', adr.includes('public.xml'));
check('ADR 宣告 values 域关闭', /values\*|values 资源域|资源域（/.test(adr));
check('证据记录 67 swatch', ev.includes('67'));
check('证据记录 wod/SpenSettingQTLayout', ev.includes('wod') && ev.includes('SpenSettingQTLayout'));
check('证据记录 Samsung IAP 整数', ev.includes('BaseDialog'));
check('证据记录限定符目录盘点', ev.includes('values-h720dp') && ev.includes('values-ldrtl') && ev.includes('values-night-v33'));
check('证据含未验证声明', ev.includes('未验证声明'));

// —— 既有登记交叉 ——
check('证据引证 ThemeStore 机制', ev.includes('setSystemDark') || ev.includes('onConfigurationUpdate'));
check('ADR 交叉引用 ADR-0671', adr.includes('ADR-0671'));

// —— Harmony 侧复核：widget 圆角 6dp 仍入册 ——
const newNoteCard = read('note/src/main/ets/noteformability/pages/RecentNotesCard.ets');
check('widget 缩略图 6dp 圆角在位', /borderRadius\(6\)|\.clip\(.*6/.test(newNoteCard) || read('note/src/main/ets/noteformability/pages/NoteThumbnailCard.ets').includes('borderRadius(6)'));
const ability = read('note/src/main/ets/noteability/NoteAbility.ets');
check('NoteAbility 系统暗色跟踪在位', ability.includes('setSystemDark') && ability.includes('onConfigurationUpdate'));

// —— 追踪 ——
check('修复总纲登记 Phase 734', read('docs/migration/audit-2026-08/修复总纲.md').includes('Phase 734'));
check('修复总纲2 登记 Phase 734', read('docs/migration/audit-2026-08/修复总纲2.md').includes('Phase 734'));
check('进展文档登记 Phase 734', read('docs/migration/reports/修复进展-2026-08-09.md').includes('Phase 734'));

console.log(`D02_ORIGINAL_VALUES_TAIL_REPLAY_OK TOTAL=${total} FAILED=${failed}`);
process.exit(failed ? 1 : 0);
