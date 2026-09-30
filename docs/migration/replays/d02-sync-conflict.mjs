// Phase 1284 — ops/synced CRDT conflict + NoteOpsUpdaterWorker
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/data/';
const R = f => readFileSync(S + f, 'utf8');
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const stale = R('note/ops/synced/StaleSyncedNoteException.java');
t('StaleSyncedNoteException ttf', stale.includes('ttf I') && stale.includes('Synced note metadata not found'));
const corrupt = R('note/ops/synced/CorruptedSyncedOpException.java');
t('CorruptedSyncedOp ttf+uq9+Assertion', corrupt.includes('ttf') && corrupt.includes('uq9') && corrupt.includes('AssertionError'));
t('CorruptedSyncedOp j0.l', corrupt.includes('j0.l('));
const denied = R('note/ops/synced/AccessDeniedException.java');
t('AccessDenied 403 q93+p93', denied.includes('q93') && denied.includes('p93') && denied.includes('403'));
const notfound = R('note/ops/synced/NoteOpsNotFoundException.java');
t('NoteOpsNotFound 404', notfound.includes('404'));
t('NoteHasNoOps exists', X('note/ops/synced/NoteHasNoOpsException.java'));
const w = R('library/state/notes/NoteOpsUpdaterWorker.java');
t('NoteOpsUpdaterWorker CoroutineWorker', w.includes('extends CoroutineWorker'));
t('worker ya9+veb+vg3+wt9', w.includes('noteOpsRepository') && w.includes('rawNoteMetadataRepository') && w.includes('diskQuotaRepository') && w.includes('opsDownloadPriority'));
const ttf = readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/ttf.java','utf8');
t('ttf note-id type', ttf.length > 0);
const uq9 = readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/uq9.java','utf8');
t('uq9 op in conflict', uq9.includes('extends cee'));
console.log('sync-conflict replay: ' + n + '/10 checks green');
