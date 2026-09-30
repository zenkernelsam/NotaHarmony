// Phase 1361 — untitled_note semantics correction + string.json format restore.
// (a) untitled_note is the e5j.h card-title fallback (default_note_title="New Note"),
//     NOT the app-shortcut label (app__shortcut_untitled_note="Untitled").
// (b) string.json keeps its original single-line { "name","value" } entry format
//     (a prior JSON.stringify reserialize had normalized to multi-line, breaking
//      text-pattern fixtures).
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const enT = readFileSync(join(root, 'note/src/main/resources/base/element/string.json'), 'utf8');
const zhT = readFileSync(join(root, 'note/src/main/resources/zh_CN/element/string.json'), 'utf8');
const en = JSON.parse(enT), zh = JSON.parse(zhT);
const get = (j, k) => (j.string.find(s => s.name === k) || {}).value;

let pass = 0; const fail = [];
const eq = (c, l) => { if (c) { pass++; console.log('ok -', l); } else { fail.push(l); console.log('FAIL -', l); } };

eq(get(en, 'untitled_note') === 'New Note', 'en untitled_note=New Note (e5j.h card fallback)');
eq(get(zh, 'untitled_note') === '新笔记', 'zh untitled_note=新笔记 (card fallback)');
eq(get(en, 'untitled_note') !== 'Untitled', 'untitled_note not shortcut-label Untitled');
// format guard: single-line entries preserved (name+value on one line for legacy entries).
eq(/\{ "name": "import_create_single", "value": "Create single note" \}/.test(enT), 'en keeps single-line entry format');
eq(/\{ "name": "untitled_note", "value": "新笔记" \}/.test(zhT), 'zh keeps single-line entry format');
// corrected values still hold after reformat-restore.
eq(get(en, 'add_page') === 'Add page', 'add_page=Add page held');
eq(get(en, 'confirm') === 'Confirm', 'confirm=Confirm held');
eq(get(en, 'dismiss') === 'Dismiss', 'dismiss=Dismiss held');
eq(get(zh, 'add_files') === '添加文件', 'zh add_files=添加文件 held');
eq(en.string.length === zh.string.length && en.string.length > 600, 'en/zh entry counts intact');

console.log(`untitled-format-restore: ${pass}/${pass + fail.length} checks green`);
if (fail.length) process.exitCode = 1;
