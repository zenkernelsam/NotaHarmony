// Phase 730 — assets/+res/raw+res/xml 尾部收口登记（文档级审计）
import fs from 'node:fs';
import path from 'node:path';

const REPO = path.resolve(process.cwd());
const R = (p) => path.join(REPO, p);
const read = (p) => fs.readFileSync(R(p), 'utf8');
const exists = (p) => fs.existsSync(R(p));

let total = 0, failed = 0;
const check = (name, cond) => {
  total++;
  if (!cond) { failed++; console.log(`  FAIL ${name}`); }
};

// === 已映射项在位 ===
check('forms_config.json 在位（widget_info 等价）',
  exists('note/src/main/resources/base/profile/forms_config.json'));
check('shortcut_* 媒体在位', exists('note/src/main/resources/base/media/shortcut_new_note.svg'));

// === ADR 登记 ===
const adr = read('docs/migration/adr/ADR-0678-original-assets-rawfile-xml-tail.md');
check('ADR-0678 存在', adr.length > 500);
check('ADR 覆盖 MyScript 桶（conf/glmath/resources）', /MyScript|glmath|conf\//.test(adr));
check('ADR 覆盖 MLKit OCR 模型桶', /mlkit|gocr|ocr/i.test(adr));
check('ADR 覆盖 ConversionRates（计费分析）', /ConversionRates/.test(adr));
check('ADR 覆盖 NoteAsset 同步 workers', /NoteAsset/.test(adr));
check('ADR 覆盖 YouTube 壳/Rive/PDFTron', /ayp_youtube|\.riv|pdftron/i.test(adr));
check('ADR 覆盖 remoteconfig defaults 工件', /remote_config_defaults|ac4/.test(adr));
check('ADR 覆盖 widget_info→forms_config', /widget_info|forms_config/.test(adr));
check('ADR 覆盖 emoji 语料登记', /emojis_unicode|emoji/.test(adr));

const ev = read('docs/migration/evidence/original-assets-rawfile-xml-tail-jadx-2026-09-25.md');
check('证据文档存在', ev.length > 400);
check('证据含 assets 分桶表', /ConversionRates|glmath/.test(ev));
check('证据含 raw/xml 分桶', /remote_config_defaults|ayp_youtube/.test(ev));

const report = read('docs/migration/reports/phase-730-original-assets-rawfile-xml-tail.md');
check('中文报告存在', report.length > 500);
check('报告引用原版证据', /assets|ConversionRates|MyScript/.test(report));

console.log(`D02_ORIGINAL_ASSETS_RAWFILE_XML_TAIL_REPLAY_OK TOTAL=${total} FAILED=${failed}`);
process.exit(failed === 0 ? 0 : 1);
