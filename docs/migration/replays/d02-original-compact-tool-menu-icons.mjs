// Desktop Replay — Phase 1382：紧凑工具/插入菜单项图标。
// EditorToolbar.buildCompactToolMenu（原版 x5f/fie 工具槽 + 插入按钮）的
// 8 个 MenuElement 现在携带 icon；验证图标映射 + 动作/门控语义保持。
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..', '..');
const src = readFileSync(join(root, 'note/src/main/ets/ui/editor/EditorToolbar.ets'), 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; } else { fail++; console.error('FAIL', name); } };

const start = src.indexOf('private buildCompactToolMenu()');
const end = src.indexOf('StateToolButton', start);
ok(start >= 0 && end > start, 'buildCompactToolMenu exists');
const body = start >= 0 ? src.slice(start, end) : '';

const cases = [
  ['whole_eraser', 'menuicon_eraser_whole'],
  ['partial_eraser', 'menuicon_eraser_partial'],
  ['selection', 'menuicon_selectrect'],
  ['add_text', 'menuicon_text'],
  ['add_files', 'menuicon_attach_file'],
  ['insert_photo', 'menuicon_insert_media'],
  ['take_photo', 'menuicon_camera'],
  ['insert_math', 'menuicon_insert_math'],
];
for (const [label, icon] of cases) {
  const re = new RegExp(`value: \\$r\\('app\\.string\\.${label}'\\), icon: \\$r\\('app\\.media\\.${icon}'\\)`);
  ok(re.test(body), `${label} → ${icon}`);
}

// 动作/门控语义保持
const actions = [
  'selectTool(ToolType.WHOLE_ERASER)',
  'selectTool(ToolType.PARTIAL_ERASER)',
  'selectTool(ToolType.SELECTION)',
  'selectTool(ToolType.DEFAULT)',
  'this.onAddFiles()',
  'this.onInsertPhotos()',
  'this.onTakePhoto()',
  'this.onInsertMath()',
];
for (const a of actions) ok(body.includes(a), `action ${a} kept`);
// 每项 photoImportLeaseActive 门控
const guards = body.match(/photoImportLeaseActive/g);
ok(guards && guards.length >= 8, 'photoImportLeaseActive guard on all items');

console.log(`RESULT PASS=${pass} FAIL=${fail}`);
process.exit(fail === 0 ? 0 : 1);
