// Phase 1316 — export + WebDAV backup layer
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/';
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const ne = readFileSync(S + 'data/NoteExporter.ets', 'utf8');
t('NoteExporter class', ne.includes('class NoteExporter'));
t('.note format', ne.includes('.note') || ne.includes('NOTE_FORMAT'));
t('snapshot guard', ne.includes('BackupSnapshotGuard') || ne.includes('assertStableBackupSnapshot'));
t('exportToFile picker', ne.includes('exportToFile'));
t('WebDAVClient', X('data/WebDAVClient.ets'));
t('WebDAVConfigStore', X('data/WebDAVConfigStore.ets'));
t('BackupBatch ops', X('data/BackupBatchApplier.ets') && X('data/BackupBatchRestorer.ets') && X('data/BackupBatchPublisher.ets'));
t('BackupSnapshotGuard', X('data/BackupSnapshotGuard.ets'));
t('BackupHash', X('data/BackupHash.ets'));
t('NoteBackupAbility+UI', X('notebackupability/NoteBackupAbility.ets') && X('ui/settings/WebDAVSettingsPage.ets'));
console.log('export-backup replay: ' + n + '/10 checks green');
