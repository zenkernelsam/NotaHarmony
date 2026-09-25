// Phase 724 — pen 调色板色名 a11y + SPen SDK 资源边界登记
// 原版证据：SpenColorSwatchUtil/SpenPenWidthMiniLayout（pen_palette_color_*/
//   pen_swatch_color_*/pen_string_* 为 SPen SDK 内部资源）。
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
const picker = read(`${SRC}/ui/components/ColorPicker.ets`);

// === 色名映射表在场 ===
check('presetColorName 映射表在场', picker.includes('presetColorName'));
check('12 预设 case 全映射', [
  '-16777216', '-7829368', '-65536', '-26368', '-256', '-16744448',
  '-16711681', '-16776961', '-8388480', '-16181', '-10011977', '-1',
].every((v) => picker.includes(`case ${v}:`)));
check('自由预设格子传 a11yName',
  /onFreeColor\(color\),\s*\n?\s*this\.presetColorName\(color\)/.test(picker));
check('colorDot 接受 a11yName 参数',
  /colorDot\(color: number, onTap:[\s\S]*?a11yName: Resource \| null/.test(picker));
check('a11y 挂 accessibilityText', picker.includes('.accessibilityText('));
check('非预设井回退 pen_string_color',
  picker.includes("pen_string_color"));

// === 资源（en 逐字 + zh）===
const EN = [
  ['pen_palette_color_black', 'Black'],
  ['pen_palette_color_gray', 'Grey'],
  ['pen_palette_color_red', 'Red'],
  ['pen_palette_color_orange', 'Orange'],
  ['pen_palette_color_yellow', 'Yellow'],
  ['pen_palette_color_green', 'Green'],
  ['pen_palette_color_turquoise', 'Turquoise'],
  ['pen_palette_color_blue', 'Blue'],
  ['pen_palette_color_purple', 'Purple'],
  ['pen_swatch_color_pink', 'Pink'],
  ['pen_palette_color_brown_sugar', 'Brown sugar'],
  ['pen_palette_color_white', 'White'],
  ['pen_string_color', 'Colour'],
];
check('en 13 键逐字', EN.every(([k, v]) =>
  stringsEn.includes(`"name": "${k}", "value": "${v}"`)));
check('zh 13 键在场', [
  '黑色', '灰色', '红色', '橙色', '黄色', '绿色', '青绿色', '蓝色',
  '紫色', '粉色', '红糖色', '白色', '颜色',
].every((v) => stringsZh.includes(`"value": "${v}"`)));

// === ADR-0672 本体 ===
const adr = read('docs/migration/adr/ADR-0672-original-pen-palette-a11y.md');
check('ADR-0672 存在', adr.length > 500);
check('ADR 登记 SPen SDK 归属', /SpenColorSwatchUtil|SpenPenWidthMiniLayout|SPen SDK/.test(adr));
check('ADR 登记 pen_string_* 边界', /pen_string/.test(adr));
check('ADR 登记 M3 内部件边界', /Material3|state_off|template_percent/.test(adr));
check('ADR 记录 Grey 英式拼写', /Grey/.test(adr));

// === 证据 + 报告 ===
const evidence = read('docs/migration/evidence/original-pen-palette-jadx-2026-09-25.md');
check('证据文档存在', evidence.length > 500);
check('证据引用 SDK 类', /SpenColorSwatchUtil/.test(evidence));
check('证据列逐字值', evidence.includes('Brown sugar') && evidence.includes('Grey'));

const report = read('docs/migration/reports/phase-724-original-pen-palette-a11y.md');
check('中文报告存在', report.length > 500);
check('报告覆盖 SPen SDK 边界', /SPen|pen_palette/.test(report));

// === 反向针 ===
check('presetColors 12 项未变',
  (picker.match(/\/\/.*$/gm) || []).length >= 0 &&
  picker.includes('private presetColors: number[]'));
check('wells 未误挂色名（井点无 a11yName 实参）',
  !/onWellColor\(color, index\)[\s\S]{0,80}?presetColorName/.test(picker));

console.log(`D02_ORIGINAL_PEN_PALETTE_A11Y_REPLAY_OK TOTAL=${total} FAILED=${failed}`);
process.exit(failed === 0 ? 0 : 1);
