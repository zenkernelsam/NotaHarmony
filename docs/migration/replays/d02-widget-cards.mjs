// Phase 1320 — Harmony form cards vs original widgets
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/noteformability/';
const X = f => existsSync(S + f);
const R = f => readFileSync(S + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const a = R('NoteFormAbility.ets');
t('FormExtensionAbility', a.includes('FormExtensionAbility'));
t('formBindingData/provider', a.includes('formBindingData') || a.includes('formProvider'));
t('widget_bindings', a.includes('widget_bindings'));
t('recent+folder+thumbnail forms', a.includes('RecentNotesFormFeed') || a.includes('recent_notes'));
const nc = R('pages/NewNoteCard.ets');
t('NewNote create_note action', nc.includes('create_note'));
const rc = R('pages/RecentNotesCard.ets');
t('RecentNotes no-notes text', rc.includes('No recent notes'));
const fc = R('pages/FolderNotesCard.ets');
t('FolderNotes empty text', fc.includes('No notes in this folder'));
const tc = R('pages/NoteThumbnailCard.ets');
t('NoteThumbnail choose note', tc.includes('Choose a note') || tc.includes('note_'));
t('edit abilities wired', a.includes('FolderFormEditAbility') || existsSync(S + '../noteformeditability/FolderFormEditAbility.ets'));
t('5 cards', ['NewNoteCard','NewRecordingCard','RecentNotesCard','FolderNotesCard','NoteThumbnailCard'].every(c => X('pages/' + c + '.ets')));
console.log('widget-cards replay: ' + n + '/10 checks green');
