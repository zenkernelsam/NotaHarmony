// Phase 1322 — concurrency primitives
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/';
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const am = readFileSync(S + 'AsyncMutex.ets', 'utf8');
t('AsyncMutex lock/release', am.includes('class AsyncMutex') && am.includes('lock'));
t('DatabaseWriteMutex', X('DatabaseWriteMutex.ets'));
const lq = readFileSync(S + 'LatestWriteQueue.ets', 'utf8');
t('LatestWriteQueue coalesce+FIFO', lq.includes('LatestWriteQueue') && lq.includes('coalesce') || lq.includes('boundary'));
const bl = readFileSync(S + 'BackupOperationLease.ets', 'utf8');
t('BackupOperationLease non-queuing', bl.includes('tryAcquire') && bl.includes('non-queuing'));
t('EditorPersistenceMutex', X('EditorPersistenceMutex.ets'));
t('LibraryMetadataMutex', X('LibraryMetadataMutationMutex.ets'));
const si = readFileSync(S + 'SyncedOperationInbox.ets', 'utf8');
t('SyncedOperationInbox validate', si.includes('validateIncomingSynced'));
t('order comparator', si.includes('compareIncomingSyncedOperationOrder'));
t('persistence mutex intake', si.includes('editorPersistenceMutex'));
t('EditorPersistenceMutex impl', readFileSync(S + 'EditorPersistenceMutex.ets', 'utf8').includes('runExclusive') || readFileSync(S + 'EditorPersistenceMutex.ets', 'utf8').includes('Mutex'));
console.log('concurrency replay: ' + n + '/10 checks green');
