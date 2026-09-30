// Phase 1306 — Harmony implementation coverage vs original
import { existsSync, readdirSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/';
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };
const count = d => existsSync(S + d) ? readdirSync(S + d, {recursive:true}).filter(f => f.endsWith('.ets')).length : 0;

t('NoteAbility main entry', X('noteability/NoteAbility.ets'));
t('NoteBackupAbility', X('notebackupability/NoteBackupAbility.ets'));
t('NoteFormAbility cards', X('noteformability/NoteFormAbility.ets'));
t('FolderNotesCard widget', X('noteformability/pages/FolderNotesCard.ets'));
t('NewRecordingCard widget', X('noteformability/pages/NewRecordingCard.ets'));
t('CRDT op codec BinaryOpCodec', X('data/BinaryOpCodec.ets'));
t('sync coordinator', X('data/IncomingOperationSyncCoordinator.ets'));
t('op compaction', X('data/OperationCompaction.ets'));
t('editor stylus adapter', X('ui/editor/ArkUIStylusAdapter.ets'));
t('data layer 100+ files', count('data') >= 100);
console.log('harmony-coverage replay: ' + n + '/10 checks green');
