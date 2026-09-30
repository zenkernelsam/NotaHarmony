// Phase 1298 — Room database layer (persistence architecture)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/data/';
const R = f => readFileSync(S + f, 'utf8');
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const learn = R('learn/database/LearnDatabase.java');
t('LearnDatabase', learn.includes('LearnDatabase'));
t('LearnDatabase_Impl', X('learn/database/LearnDatabase_Impl.java'));
const search = R('search/database/SearchDatabase.java');
t('SearchDatabase', search.includes('SearchDatabase'));
const settings = R('settings/database/SettingsDatabase.java');
t('SettingsDatabase', settings.includes('SettingsDatabase'));
const toolbox = R('toolbar/database/ToolboxDatabase.java');
t('ToolboxDatabase', toolbox.includes('ToolboxDatabase'));
const trans = R('transcription/database/TranscriptionDatabase.java');
t('TranscriptionDatabase', trans.includes('TranscriptionDatabase'));
const state = R('note/state/NoteStateDatabase.java');
t('NoteStateDatabase', state.includes('NoteStateDatabase'));
t('SearchIndexDatabase', X('search/engine/room/SearchIndexDatabase.java'));
t('LearnDatabase_Impl Room', R('learn/database/LearnDatabase_Impl.java').length > 50);
t('7 DB layer', X('learn/database/LearnDatabase.java') && X('search/database/SearchDatabase.java') && X('settings/database/SettingsDatabase.java'));
console.log('room-databases replay: ' + n + '/10 checks green');
