// D02 原版 1.4.2 内置纸张模板包格式 — Phase 761（ADR-0708 版本差待审细化）
// 钉住 papertemplates/ 包清单 schema、文件命名规则与 35 包目录基数。
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const base = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/assets/papertemplates';

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('papertemplates asset root exists (1.4.2-only surface)',
  fs.existsSync(base));

const dirs = fs.readdirSync(base).filter(d =>
  fs.statSync(path.join(base, d)).isDirectory());
check('exactly 35 bundled template packs', dirs.length === 35);

const metas = dirs.map(d => JSON.parse(
  fs.readFileSync(path.join(base, d, 'metadata.json'), 'utf8')));
check('every pack carries uuid/name/paperSizes/defaultPaperSize/colors/category',
  metas.every(m => typeof m.uuid === 'string' && typeof m.name === 'string' &&
    Array.isArray(m.paperSizes) && typeof m.defaultPaperSize === 'string' &&
    Array.isArray(m.colors) && typeof m.category === 'string'));

check('category domain matches ui_papertemplates__* families',
  [...new Set(metas.map(m => m.category))].sort().join(',') ===
  'academic,creative,notepads,planning,selfCare');

check('cornell reference pack carries the canonical schema example',
  metas.find(m => m.name === 'Cornell Note')?.uuid ===
  '9593C04C-E38E-4510-BE1F-F07A754A226D');

const cornellPdfs = fs.readdirSync(path.join(base, 'cornell'))
  .filter(f => f.endsWith('.pdf'));
check('dual-orientation pack emits {Name}_{Size}_{hex}_{orientation}.pdf',
  cornellPdfs.length === 36 &&
  cornellPdfs.includes('Cornell_A3_f8f1bf_landscape.pdf'));

const isoPdfs = fs.readdirSync(path.join(base, 'isometic'))
  .filter(f => f.endsWith('.pdf'));
check('single-orientation pack omits the orientation segment',
  isoPdfs.length === 4 && isoPdfs.includes('Isometic_A4_000000.pdf'));

check('packs ship thumbnails in mixed HEIC/PNG (light/dark/orientation variants)',
  fs.existsSync(path.join(base, 'cornell', 'thumb.png')) &&
  fs.existsSync(path.join(base, 'cornell', 'thumb_landscape.png')) &&
  fs.existsSync(path.join(base, 'college_rule', 'thumb_black.png')) &&
  fs.existsSync(path.join(base, 'assignment_planner', 'thumb.heic')));

const ev = fs.readFileSync(
  'docs/migration/evidence/phase-761-original-paper-template-bundles.md', 'utf8');
check('Phase 761 evidence registers schema + 35-pack catalog',
  ev.includes('9593C04C-E38E-4510-BE1F-F07A754A226D') &&
  ev.includes('tianzege') && ev.includes('35'));

console.log(`D02_ORIGINAL_PAPER_TEMPLATE_BUNDLES_OK TOTAL=${checks.length} FAILED=0`);
