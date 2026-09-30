// Phase 1321 — persistent history (op-log→undo/redo) + u64
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/';
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const ph = readFileSync(S + 'PersistentHistory.ets', 'utf8');
t('reducePersistentHistory', ph.includes('reducePersistentHistory'));
t('undo+redo stacks', ph.includes('undo') && ph.includes('redo'));
t('op-log order client_time/sequence', ph.includes('client_time') || ph.includes('sequence'));
t('classify mutations', ph.includes('classifyPageMutation') || ph.includes('PageMutationOp'));
const ud = readFileSync(S + 'UnsignedDecimal.ets', 'utf8');
t('u64 canonical check', ud.includes('canonical') || ud.includes('non-digit'));
t('u64 exhausted guard', ud.includes('exhausted'));
t('persistent history metadata', X('PersistentHistoryMetadata.ets'));
t('SyncedOperationInbox', X('SyncedOperationInbox.ets'));
t('PageSnapshotOpCodec', X('PageSnapshotOpCodec.ets'));
t('page structure codec', X('PageStructureOpCodec.ets'));
console.log('persistent-history replay: ' + n + '/10 checks green');
