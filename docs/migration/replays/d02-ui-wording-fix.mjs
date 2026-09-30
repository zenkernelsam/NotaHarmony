// Phase 1358 — UI wording fixes applied (code change)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const B = 'C:/HarmonyProject/NotaHarmony/note/src/main/resources/base/element/string.json';
const Z = 'C:/HarmonyProject/NotaHarmony/note/src/main/resources/zh_CN/element/string.json';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const en = JSON.parse(readFileSync(B, 'utf8'));
const zh = JSON.parse(readFileSync(Z, 'utf8'));
const get = (j, k) => (j.string.find(s => s.name === k) || {}).value;

t('en untitled=Untitled', get(en, 'untitled_note') === 'Untitled');
t('en recent desc byte-exact', get(en, 'form_recent_notes_desc') === 'Quick access to your recent notes.');
t('en folder desc byte-exact', get(en, 'form_folder_notes_desc') === 'Quick access to notes from one of your folders.');
t('en folder display=Folder', get(en, 'form_folder_notes_display') === 'Folder');
t('zh untitled=未命名', get(zh, 'untitled_note') === '未命名');
t('zh recent desc', get(zh, 'form_recent_notes_desc').includes('快速访问'));
t('zh folder display=文件夹', get(zh, 'form_folder_notes_display') === '文件夹');
t('zh folder desc', get(zh, 'form_folder_notes_desc').includes('快速访问'));
t('en new_note still byte-exact', get(en, 'form_new_note_desc') === 'Quickly create a new note.');
t('zh untitled not 新笔记', get(zh, 'untitled_note') !== '新笔记');
console.log('ui-wording-fix replay: ' + n + '/10 checks green');
