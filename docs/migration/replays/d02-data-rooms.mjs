// Phase 1174 — data/ remaining Room DBs (settings/toolbox/search×2/transcription)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const B = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/data/';
const has = f => existsSync(B + f);
const R = f => readFileSync(B + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };
const room = f => has(f) && R(f).includes('extends x5c');

t('SettingsDatabase Room', room('settings/database/SettingsDatabase.java'));
t('ToolboxDatabase Room', room('toolbar/database/ToolboxDatabase.java'));
t('SearchIndexDatabase Room', room('search/engine/room/SearchIndexDatabase.java'));
t('SearchDatabase Room', room('search/database/SearchDatabase.java'));
t('TranscriptionDatabase Room', room('transcription/database/TranscriptionDatabase.java'));
t('all 5 have _Impl', has('settings/database/SettingsDatabase_Impl.java') && has('toolbar/database/ToolboxDatabase_Impl.java') && has('search/engine/room/SearchIndexDatabase_Impl.java') && has('search/database/SearchDatabase_Impl.java') && has('transcription/database/TranscriptionDatabase_Impl.java'));
// full data/ Room census (incl prior phases)
t('note rooms present', room('note/assets/NoteAssetDatabase.java') && room('note/ops/database/NoteBundleMetadataDatabase.java') && room('note/state/NoteStateDatabase.java'));
t('library room present', room('library/state/database/RawLibraryStateDatabase.java'));
t('learn room present', room('learn/database/LearnDatabase.java'));
t('10 Room DBs total in named data/', ['note/assets/NoteAssetDatabase.java','note/ops/database/NoteBundleMetadataDatabase.java','note/state/NoteStateDatabase.java','library/state/database/RawLibraryStateDatabase.java','learn/database/LearnDatabase.java','search/engine/room/SearchIndexDatabase.java','search/database/SearchDatabase.java','settings/database/SettingsDatabase.java','toolbar/database/ToolboxDatabase.java','transcription/database/TranscriptionDatabase.java'].filter(room).length===10);
console.log('data-rooms replay: ' + n + '/10 checks green');
