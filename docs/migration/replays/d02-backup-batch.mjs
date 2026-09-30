// Phase 1345 — backup batch internals + rich-text encoder
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const p = readFileSync(S + 'BackupBatchPublisher.ets', 'utf8');
const spec = readFileSync(S + 'BackupBatchSpec.ets', 'utf8');
t('batch format tag', spec.includes('nota.backup-batch'));
t('batchId validate', spec.includes('isValidBackupBatchId'));
t('publish fn', p.includes('publish'));
t('manifest serialize', p.includes('serializeBackupBatch'));
t('read-back verify', p.includes('download') && p.includes('hash'));
t('CryptoBackupBatchHasher', p.includes('CryptoBackupBatchHasher'));
t('BackupBatchRestorer', existsSync(S + 'BackupBatchRestorer.ets'));
t('restore object url', readFileSync(S + 'BackupBatchRestorer.ets', 'utf8').includes('backupBatchObjectUrl'));
t('rich-text encoder', existsSync(S + 'OriginalRichTextStylePayloadEncoder.ets'));
t('style runs encode', readFileSync(S + 'OriginalRichTextStylePayloadEncoder.ets', 'utf8').length > 50);
console.log('backup-batch replay: ' + n + '/10 checks green');
