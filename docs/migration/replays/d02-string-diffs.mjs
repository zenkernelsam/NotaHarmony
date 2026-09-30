// Phase 1359 — second-batch string case/wording fixes
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const B = 'C:/HarmonyProject/NotaHarmony/note/src/main/resources/base/element/string.json';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const en = JSON.parse(readFileSync(B, 'utf8'));
const get = k => (en.string.find(s => s.name === k) || {}).value;

t('new_note=New Note', get('new_note') === 'New Note');
t('add_page=Add page', get('add_page') === 'Add page');
t('more_page_actions=More actions', get('more_page_actions') === 'More actions');
t('copy_note_id=Copy note ID', get('copy_note_id') === 'Copy note ID');
t('pages_deselect_all=Deselect All', get('pages_deselect_all') === 'Deselect All');
t('show_in_folder=Show in folder', get('show_in_folder') === 'Show in folder');
t('untitled still Untitled', get('untitled_note') === 'Untitled');
t('untitled_note not New Note', get('untitled_note') !== 'New Note');
t('json has entries', en.string.length > 100);
t('no empty untitled', get('untitled_note').length > 0);
console.log('string-diffs replay: ' + n + '/10 checks green');
