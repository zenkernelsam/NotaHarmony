// Phase 1300 (milestone) — data-layer + app-architecture census
import { readFileSync, existsSync, readdirSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/';
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('app shell', X('app/NbApplication.java') && X('app/MainActivity.java'));
t('app widgets', X('app/widgets/CreateNoteWidget.kt') || X('app/widgets'));
t('auth/login feature', existsSync(S + 'feature/login/apple') && existsSync(S + 'feature/login/microsoft'));
t('core infra', existsSync(S + 'core/analytics') && existsSync(S + 'core/glmath'));
t('data billing', existsSync(S + 'data/billing'));
t('data learn', existsSync(S + 'data/learn/database/LearnDatabase.java'));
t('data note ops', existsSync(S + 'data/note/ops/synced'));
t('data search', existsSync(S + 'data/search'));
t('8 DBs', X('data/learn/database/LearnDatabase.java') && X('data/search/database/SearchDatabase.java') && X('data/settings/database/SettingsDatabase.java') && X('data/toolbar/database/ToolboxDatabase.java') && X('data/transcription/database/TranscriptionDatabase.java') && X('data/note/assets/NoteAssetDatabase.java') && X('data/note/state/NoteStateDatabase.java') && X('data/note/ops/database/NoteBundleMetadataDatabase.java'));
t('domain subscription', existsSync(S + 'domain/subscription'));
console.log('data-layer-census replay: ' + n + '/10 checks green');
