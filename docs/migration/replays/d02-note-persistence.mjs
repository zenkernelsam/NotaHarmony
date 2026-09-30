// Phase 1173 — data/note persistence (3 Room DBs + sealed asset-transfer worker + 5 sync exceptions)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const B = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/data/note/';
const has = f => existsSync(B + f);
const R = f => readFileSync(B + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('NoteAssetDatabase Room', has('assets/NoteAssetDatabase.java') && R('assets/NoteAssetDatabase.java').includes('extends x5c'));
t('NoteBundleMetadataDatabase Room', has('ops/database/NoteBundleMetadataDatabase.java') && R('ops/database/NoteBundleMetadataDatabase.java').includes('extends x5c'));
t('NoteStateDatabase Room', has('state/NoteStateDatabase.java') && R('state/NoteStateDatabase.java').includes('extends x5c'));
t('all 3 have _Impl', has('assets/NoteAssetDatabase_Impl.java') && has('ops/database/NoteBundleMetadataDatabase_Impl.java') && has('state/NoteStateDatabase_Impl.java'));
const tw = R('assets/NoteAssetTransferWorker.java');
t('NoteAssetTransferWorker CoroutineWorker', tw.includes('extends CoroutineWorker'));
t('TransferWorker sealed (Download+Upload)', has('assets/NoteAssetDownloadWorker.java') && has('assets/NoteAssetUploadWorker.java'));
t('DownloadWorker extends TransferWorker', R('assets/NoteAssetDownloadWorker.java').includes('extends NoteAssetTransferWorker'));
t('UploadWorker extends TransferWorker', R('assets/NoteAssetUploadWorker.java').includes('extends NoteAssetTransferWorker'));
t('synced exceptions exist', ['AccessDeniedException','CorruptedSyncedOpException','NoteHasNoOpsException','NoteOpsNotFoundException','StaleSyncedNoteException'].every(f=>has('ops/synced/'+f+'.java')));
t('CorruptedSyncedOpException extends Exception', R('ops/synced/CorruptedSyncedOpException.java').includes('extends Exception'));
console.log('note-persistence replay: ' + n + '/10 checks green');
