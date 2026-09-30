// Phase 1351 — UI wording fidelity vs original strings.xml
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/resources/base/element/string.json';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const j = readFileSync(S, 'utf8');
t('"Tap to open Notability"', j.includes('Tap to open Notability'));
t('"No notes in this folder"', j.includes('No notes in this folder'));
t('"No recent notes"', j.includes('No recent notes'));
t('"No notes yet"', j.includes('No notes yet'));
t('"Choose a note"', j.includes('Choose a note'));
t('"Create a new note"', j.includes('Create a new note'));
t('"Start recording"', j.includes('Start recording'));
t('"Recent Notes"', j.includes('Recent Notes'));
t('"Quickly create a new note."', j.includes('Quickly create a new note.'));
t('folder empty rich copy', j.includes('This folder is empty'));
console.log('ui-wording replay: ' + n + '/10 checks green');
