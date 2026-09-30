// Phase 1343 — op applier family + state stores
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const ap = readFileSync(S + 'OriginalAddPathElementsOperation.ets', 'utf8');
t('add-path applier', ap.includes('apply') && ap.includes('applyPayload'));
t('ink-path append decode', ap.includes('InkPathAppend') || ap.includes('DecodedOriginalInkPathAppend'));
t('identity validate', ap.includes('validateOperationIdentity'));
t('conflict detection', ap.includes('conflicts with persisted'));
t('partial-state guard', ap.includes('partial persisted state'));
t('RdbStore apply', ap.includes('relationalStore'));
t('ModifyInk op', existsSync(S + 'OriginalModifyInkOperation.ets'));
t('ModifyPositions op', existsSync(S + 'OriginalModifyPositionsOperation.ets'));
t('TransientInteraction op', existsSync(S + 'OriginalTransientInteractionOperation.ets'));
t('OutboundOperationRepair', existsSync(S + 'OriginalOutboundOperationRepair.ets'));
console.log('op-appliers replay: ' + n + '/10 checks green');
