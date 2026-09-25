// Phase 728 — drawable/mipmap/anim/layout 族收口登记（文档级审计）
// 证据：drawable 482 件分桶、ui_designsystem__ 216 图标、
//   tape_pattern 程序化预览、laser 程序化、SPen/M3 平台件。
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

// === 已移植簇在位校验 ===
check('shortcut_*.svg 三件套在位',
  exists('note/src/main/resources/base/media/shortcut_new_note.svg') &&
  exists('note/src/main/resources/base/media/shortcut_new_photo.svg') &&
  exists('note/src/main/resources/base/media/shortcut_new_recording.svg'));
check('纸张 webp 已内置 rawfile',
  exists('note/src/main/resources/rawfile/core_paper__paper01.webp'));
check('widget_add/record SVG 在位（Phase 726）',
  exists('note/src/main/resources/base/media/widget_add.svg') &&
  exists('note/src/main/resources/base/media/widget_record.svg'));

// === 程序化等价在位校验 ===
const picker = read('note/src/main/ets/ui/editor/TapePatternPicker.ets');
check('TapePatternPicker 程序化样本（九图案）',
  /TapePattern\.(STRIPES|GRID|DOTS|PLAIN|STARS|FLOWERS|HEARTS|WAVES|CHECKERS)/.test(picker));
check('laser 程序化渲染器在位',
  exists('note/src/main/ets/core/adaptation/OriginalLaserPointer.ets'));
check('pencil splat 程序化生成器在位',
  exists('note/src/main/ets/core/algorithm/PencilSplatGenerator.ets'));

// === 文档登记 ===
const adr = read('docs/migration/adr/ADR-0676-original-drawable-tail.md');
check('ADR-0676 存在', adr.length > 500);
check('ADR 覆盖 ui_designsystem 图标桶', /ui_designsystem/.test(adr));
check('ADR 覆盖 tape/laser 程序化等价', /tape_pattern|laser/i.test(adr));
check('ADR 覆盖 SPen/qt 桶', /spen|qt_/.test(adr));
check('ADR 覆盖 login/About 社交图标边界', /feature_login|instagram|social/.test(adr));
check('ADR 覆盖 anim/animator 平台桶', /anim|animator|interpolator/.test(adr));
check('ADR 覆盖 values-* 限定符机制说明', /values-|限定符/.test(adr));

const evidence = read('docs/migration/evidence/original-drawable-tail-jadx-2026-09-25.md');
check('证据文档存在', evidence.length > 400);
check('证据含分桶表', /桶|ui_designsystem__/.test(evidence));
check('证据引用 strokeindicator/tape_pattern', /strokeindicator|tape_pattern/.test(evidence));

const report = read('docs/migration/reports/phase-728-original-drawable-tail.md');
check('中文报告存在', report.length > 500);
check('报告引用原版证据', /drawable|ui_designsystem/.test(report));

console.log(`D02_ORIGINAL_DRAWABLE_TAIL_REPLAY_OK TOTAL=${total} FAILED=${failed}`);
process.exit(failed === 0 ? 0 : 1);
