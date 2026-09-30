// Phase 1293 — note asset sync workers
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/data/note/assets/';
const R = f => readFileSync(S + f, 'utf8');
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('NoteAssetDatabase Room', R('NoteAssetDatabase.java').includes('extends x5c'));
t('NoteAssetDatabase_Impl', X('NoteAssetDatabase_Impl.java'));
const tw = R('NoteAssetTransferWorker.java');
t('TransferWorker CoroutineWorker', tw.includes('CoroutineWorker'));
t('TransferWorker k19 continuation', tw.includes('k19') && tw.includes('abstract class'));
const dw = R('NoteAssetDownloadWorker.java');
t('DownloadWorker extends Transfer', dw.includes('extends NoteAssetTransferWorker'));
t('DownloadWorker c(k19)', dw.includes('c(k19'));
t('DownloadWorker p29 repo', dw.includes('p29'));
t('UploadWorker', X('NoteAssetUploadWorker.java'));
const uw = R('NoteAssetUploadWorker.java');
t('UploadWorker extends Transfer', uw.includes('extends NoteAssetTransferWorker'));
const bwt = X('NoteAssetTransferWorker.java');
t('base+subclass structure', bwt && X('NoteAssetDownloadWorker.java') && X('NoteAssetUploadWorker.java'));
console.log('asset-sync replay: ' + n + '/10 checks green');
