// Phase 1172 — data/library/state (library-state Room + export provider + upload workers)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const B = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/data/library/state/';
const has = f => existsSync(B + f);
const R = f => readFileSync(B + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ExportFileProvider exists', has('ExportFileProvider.java'));
t('ExportFileProvider extends ye4 (FileProvider)', R('ExportFileProvider.java').includes('extends ye4'));
t('ExportSweepWorker extends CoroutineWorker', R('ExportSweepWorker.java').includes('extends CoroutineWorker'));
t('ExportSweepWorker suspend doWork', R('ExportSweepWorker.java').includes('b(ef2'));
t('LibraryStateUploaderWorker CoroutineWorker', R('LibraryStateUploaderWorker.java').includes('extends CoroutineWorker'));
t('LibraryStateUploaderWorker suspend', R('LibraryStateUploaderWorker.java').includes('b(ef2'));
t('RawLibraryStateDatabase Room', has('database/RawLibraryStateDatabase.java') && R('database/RawLibraryStateDatabase.java').includes('extends x5c'));
t('NoteAccessDeniedException IOException', R('NoteAccessDeniedException.java').includes('extends IOException'));
t('NoteNotFoundException IOException', R('NoteNotFoundException.java').includes('extends IOException'));
t('folder exceptions: InvalidFolderName + MaxDepth', has('folders/InvalidFolderNameException.java') && has('folders/MaxFolderDepthExceededException.java'));
console.log('library-state replay: ' + n + '/10 checks green');
