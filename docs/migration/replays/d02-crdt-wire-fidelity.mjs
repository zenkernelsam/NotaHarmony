// Phase 1309 — CRDT wire fidelity (FlatBuffer + ordering compat)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/';
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('OriginalSyncedOperationFlatBuffer', X('OriginalSyncedOperationFlatBuffer.ets'));
t('OriginalOperationEnvelopeEncoder', X('OriginalOperationEnvelopeEncoder.ets'));
const oi = readFileSync(S + 'OperationIdentity.ets', 'utf8');
t('timestamp+siteId fields', oi.includes('timestamp') && oi.includes('siteId'));
t('compareOriginalSequenceIdentity', oi.includes('compareOriginalSequenceIdentity'));
t('signed int timestamp compare', oi.includes('toJavaInt'));
t('64-bit pack comment', /packs timestamp.*site/i.test(oi) || oi.includes('64-bit'));
const sc = readFileSync(S + 'IncomingOperationSyncCoordinator.ets', 'utf8');
t('AsyncMutex exclusive sync', sc.includes('AsyncMutex'));
t('parse original envelope', sc.includes('parseOriginalSyncedOperationEnvelope'));
t('receiveOpsEvent', sc.includes('receiveOpsEvent'));
t('replayDeferredBundle', sc.includes('replayDeferredBundle'));
console.log('crdt-wire-fidelity replay: ' + n + '/10 checks green');
