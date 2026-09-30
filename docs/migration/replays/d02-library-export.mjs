// Phase 1294 — library export provider + upload + folder rules
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/data/library/state/';
const R = f => readFileSync(S + f, 'utf8');
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const efp = R('ExportFileProvider.java');
t('ExportFileProvider extends ye4', efp.includes('extends ye4'));
t('openFile ParcelFileDescriptor', efp.includes('ParcelFileDescriptor') && efp.includes('openFile'));
t('exports path segment', efp.includes('"exports"'));
t('OnClose reclaim tracking', efp.includes('OnCloseListener') && efp.includes('reclaim'));
t('ExportSweepWorker', X('ExportSweepWorker.java'));
t('LibraryStateUploaderWorker', X('LibraryStateUploaderWorker.java'));
t('InvalidFolderNameException', X('folders/InvalidFolderNameException.java'));
t('MaxFolderDepthExceededException', X('folders/MaxFolderDepthExceededException.java'));
t('RawLibraryStateDatabase', X('database/RawLibraryStateDatabase.java'));
t('NoteAccessDenied+Retryable+UploadInProgress', X('NoteAccessDeniedException.java') && X('RetryableUploadException.java') && X('UploadInProgressException.java'));
console.log('library-export replay: ' + n + '/10 checks green');
