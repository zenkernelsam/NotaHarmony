// Phase 1360 — wording fidelity batch 3.
// Asserts the Harmony base/zh_CN string resources match the original
// decompiled strings.xml values for the keys corrected in this phase, and
// that the intentionally-retained adapted keys were NOT regressed.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const base = JSON.parse(readFileSync(join(root, 'note/src/main/resources/base/element/string.json'), 'utf8'));
const zh = JSON.parse(readFileSync(join(root, 'note/src/main/resources/zh_CN/element/string.json'), 'utf8'));
const bmap = {}; (base.string || []).forEach((e) => { bmap[e.name] = e.value; });
const zmap = {}; (zh.string || []).forEach((e) => { zmap[e.name] = e.value; });

let pass = 0; const fail = [];
const eq = (cond, label) => { if (cond) { pass++; console.log('ok -', label); } else { fail.push(label); console.log('FAIL -', label); } };

// 1-6 — English toolbox/jump/dialog fidelity fixes now match original.
eq(bmap.confirm === 'Confirm', 'confirm -> Confirm');
eq(bmap.dismiss === 'Dismiss', 'dismiss -> Dismiss');
eq(bmap.add_files === 'Add Files', 'add_files -> Add Files');
eq(bmap.insert_math === 'Insert Math', 'insert_math -> Insert Math');
eq(bmap.take_photo === 'Take Photo', 'take_photo -> Take Photo');
eq(bmap.reset_to_default === 'Reset to default', 'reset_to_default -> Reset to default');

// 7-8 — zh_CN semantic-sync fixes for the same keys.
eq(zmap.dismiss === '取消', 'zh dismiss -> 取消');
eq(zmap.add_files === '添加文件', 'zh add_files -> 添加文件');

// 9 — untitled_note still correct from Phase 1358 (regression guard).
eq(bmap.untitled_note === 'Untitled', 'untitled_note stays Untitled');
// 10 — pages_deselect_all still Title Case from Phase 1359 (regression guard).
eq(bmap.pages_deselect_all === 'Deselect All', 'pages_deselect_all stays Deselect All');

console.log(`wording-fidelity-b3: ${pass}/${pass + fail.length} checks green`);
if (fail.length) { process.exitCode = 1; }
