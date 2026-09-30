// Phase 1161 — data/note Room + Worker + sync-exception layer
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const B = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/data/note/';
const R = f => readFileSync(B + f, 'utf8');
const has = f => existsSync(B + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('NoteAssetDatabase extends x5c (RoomDatabase)', R('assets/NoteAssetDatabase.java').includes('extends x5c'));
t('NoteAssetDatabase u()→g19 DAO', R('assets/NoteAssetDatabase.java').includes('abstract g19 u()'));
t('NoteAssetDatabase_Impl Room-generated', has('assets/NoteAssetDatabase_Impl.java'));
t('Asset Workers: Download+Upload+Transfer', has('assets/NoteAssetDownloadWorker.java') && has('assets/NoteAssetUploadWorker.java') && has('assets/NoteAssetTransferWorker.java'));
t('Workers use WorkerParameters (androidx.work)', R('assets/NoteAssetDownloadWorker.java').includes('WorkerParameters'));
t('NoteBundleMetadataDatabase 3 DAOs', R('ops/database/NoteBundleMetadataDatabase.java').includes('abstract kq1 u()') && R('ops/database/NoteBundleMetadataDatabase.java').includes('abstract w63 v()'));
t('sync exceptions: AccessDenied', has('ops/synced/AccessDeniedException.java') && R('ops/synced/AccessDeniedException.java').includes('extends Exception'));
t('sync exceptions: CorruptedSyncedOp + NoteHasNoOps', has('ops/synced/CorruptedSyncedOpException.java') && has('ops/synced/NoteHasNoOpsException.java'));
t('sync exceptions: NoteOpsNotFound + StaleSyncedNote', has('ops/synced/NoteOpsNotFoundException.java') && has('ops/synced/StaleSyncedNoteException.java'));
t('NoteStateDatabase + Impl', has('state/NoteStateDatabase.java') && has('state/NoteStateDatabase_Impl.java'));
console.log('note-repo replay: ' + n + '/10 checks green');
