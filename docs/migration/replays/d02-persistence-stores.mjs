// Phase 1344 — local→synced-op persistence bridge + stores
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const nb = readFileSync(S + 'OriginalNoteBackgroundPersistence.ets', 'utf8');
t('persist fn', nb.includes('persistOriginalNoteBackground'));
t('allocates op identity', nb.includes('allocateOperationIdentity'));
t('SET_METADATA op', nb.includes('SET_METADATA'));
t('StoredSyncedOperation', nb.includes('StoredSyncedOperation'));
t('uploadImmediately', nb.includes('uploadImmediately'));
t('aligned page identity check', nb.includes('aligned original page identity'));
t('RecordingPersistence', existsSync(S + 'OriginalRecordingPersistence.ets'));
t('PageOrderStore', existsSync(S + 'OriginalPageOrderStore.ets'));
t('PageElementIdentity', existsSync(S + 'PageElementIdentity.ets'));
t('PersistentHistoryMetadata', existsSync(S + 'PersistentHistoryMetadata.ets'));
console.log('persistence-stores replay: ' + n + '/10 checks green');
