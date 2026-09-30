// Phase 1162 — data/library repository + Workers + domain exceptions
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const B = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/data/library/';
const R = f => readFileSync(B + f, 'utf8');
const has = f => existsSync(B + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('RawLibraryStateDatabase extends x5c', R('state/database/RawLibraryStateDatabase.java').includes('extends x5c'));
t('RawLibraryStateDatabase 3 DAOs', R('state/database/RawLibraryStateDatabase.java').includes('abstract jp1 u()') && R('state/database/RawLibraryStateDatabase.java').includes('abstract n78 w()'));
t('RawLibraryStateDatabase_Impl', has('state/database/RawLibraryStateDatabase_Impl.java'));
t('ExportFileProvider extends ye4', R('state/ExportFileProvider.java').includes('extends ye4'));
t('ExportSweepWorker CoroutineWorker', R('state/ExportSweepWorker.java').includes('extends CoroutineWorker'));
t('LibraryStateUploaderWorker + NoteOpsUpdaterWorker', has('state/LibraryStateUploaderWorker.java') && has('state/notes/NoteOpsUpdaterWorker.java'));
t('folder exceptions', has('state/folders/InvalidFolderNameException.java') && has('state/folders/MaxFolderDepthExceededException.java'));
t('MaxFolderDepthExceededException(int)', R('state/folders/MaxFolderDepthExceededException.java').includes('MaxFolderDepthExceededException(int i)'));
t('note exceptions', has('state/NoteAccessDeniedException.java') && has('state/NoteNotFoundException.java'));
t('ntb MissingAssets + upload exceptions', has('state/ntb/MissingAssetsException.java') && has('state/RetryableUploadException.java') && has('state/UploadInProgressException.java'));
console.log('library-repo replay: ' + n + '/10 checks green');
