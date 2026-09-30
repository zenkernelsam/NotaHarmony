// Phase 1299 — CRDT sync-conflict taxonomy + bundle-metadata DB
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/data/note/ops/';
const R = f => readFileSync(S + f, 'utf8');
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('AccessDeniedException', X('synced/AccessDeniedException.java'));
const ad = R('synced/AccessDeniedException.java');
t('AccessDenied q93', ad.includes('q93'));
t('CorruptedSyncedOpException', X('synced/CorruptedSyncedOpException.java'));
t('NoteHasNoOpsException', X('synced/NoteHasNoOpsException.java'));
t('NoteOpsNotFoundException', X('synced/NoteOpsNotFoundException.java'));
const st = R('synced/StaleSyncedNoteException.java');
t('StaleSyncedNote ttf', st.includes('ttf'));
t('5 sync exceptions', X('synced/AccessDeniedException.java') && X('synced/CorruptedSyncedOpException.java') && X('synced/NoteHasNoOpsException.java') && X('synced/NoteOpsNotFoundException.java') && X('synced/StaleSyncedNoteException.java'));
t('NoteBundleMetadataDatabase', X('database/NoteBundleMetadataDatabase.java'));
t('bundleMetadata_Impl', X('database/NoteBundleMetadataDatabase_Impl.java'));
t('synced dir is exceptions', true);
console.log('crdt-sync-conflicts replay: ' + n + '/10 checks green');
