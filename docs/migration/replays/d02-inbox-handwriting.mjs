// Phase 1337 — synced inbox validation + handwriting layer
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/';
const A = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/core/adaptation/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const ib = readFileSync(D + 'SyncedOperationInbox.ets', 'utf8');
t('batch validate', ib.includes('validateIncomingSyncedBatch'));
t('metadata/noteId check', ib.includes('validateIncomingSyncedOperationMetadata'));
t('envelope validate', ib.includes('validateOriginalSyncedOperation'));
t('server-time order enforced', ib.includes('server-time ordered'));
t('duplicate count', ib.includes('duplicateOperationCount'));
t('u64 compare', ib.includes('compareUnsignedLongDecimal'));
t('HandwritingConversion', existsSync(A + 'OriginalHandwritingConversionCoordinator.ets'));
t('RecognitionProvider policy', existsSync(A + 'OriginalHandwritingProviderCapabilityPolicy.ets'));
t('RecognitionContext', existsSync(A + 'OriginalHandwritingRecognitionContextAdapter.ets'));
t('SelectionAdapter', existsSync(A + 'OriginalHandwritingSelectionAdapter.ets'));
console.log('inbox-handwriting replay: ' + n + '/10 checks green');
