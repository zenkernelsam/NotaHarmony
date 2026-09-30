// Phase 1362 — paper/template picker label fidelity.
// template_lines -> "Rule" (original core_paper__rule="Rule"; the lined template
// is labelled "Rule", not "Lines").  paper_size -> "Size" (ui_templates__size).
// Regression guards: template_plain/grid/dots + portrait/landscape still match.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const en = JSON.parse(readFileSync(join(root, 'note/src/main/resources/base/element/string.json'), 'utf8'));
const zh = JSON.parse(readFileSync(join(root, 'note/src/main/resources/zh_CN/element/string.json'), 'utf8'));
const get = (j, k) => (j.string.find(s => s.name === k) || {}).value;

let pass = 0; const fail = [];
const eq = (c, l) => { if (c) { pass++; console.log('ok -', l); } else { fail.push(l); console.log('FAIL -', l); } };

eq(get(en, 'template_lines') === 'Rule', 'template_lines=Rule (core_paper__rule)');
eq(get(en, 'paper_size') === 'Size', 'paper_size=Size (ui_templates__size)');
eq(get(zh, 'paper_size') === '尺寸', 'zh paper_size=尺寸');
eq(get(zh, 'template_lines') === '横线', 'zh template_lines=横线 (ruled lines)');
eq(get(en, 'template_plain') === 'Plain', 'template_plain=Plain held');
eq(get(en, 'template_grid') === 'Grid', 'template_grid=Grid held');
eq(get(en, 'template_dots') === 'Dots', 'template_dots=Dots held');
eq(get(en, 'portrait') === 'Portrait', 'portrait=Portrait held');
eq(get(en, 'landscape') === 'Landscape', 'landscape=Landscape held');
eq(get(en, 'page_orientation') === 'Orientation', 'page_orientation=Orientation held');

console.log(`paper-template-labels: ${pass}/${pass + fail.length} checks green`);
if (fail.length) process.exitCode = 1;
