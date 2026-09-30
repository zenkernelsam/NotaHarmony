// Phase 1163 — data/transcription + stylus + search repositories
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const B = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/data/';
const R = f => readFileSync(B + f, 'utf8');
const has = f => existsSync(B + f);
const TE = R('transcription/TranscriptionException.java');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('TranscriptionException sealed', TE.includes('abstract class TranscriptionException'));
t('10 subtypes in metadata', TE.includes('QuotaExceeded') && TE.includes('PollingExhausted') && TE.includes('ServerTransientError') && TE.includes('TooManyErrors'));
t('LiveTranscriptionHttpException', has('transcription/livetranscription/LiveTranscriptionHttpException.java') && R('transcription/livetranscription/LiveTranscriptionHttpException.java').includes('LiveTranscriptionHttpException(int i, String str)'));
t('TranscriptionNotFoundException', has('transcription/TranscriptionNotFoundException.java'));
t('GCSUploadException (Google Cloud)', has('transcription/upload/GCSUploadException.java'));
t('TranscriptionDatabase Room', has('transcription/database/TranscriptionDatabase.java') && has('transcription/database/TranscriptionDatabase_Impl.java'));
t('stylus HapticPreferencesInitializer', R('stylus/haptic/HapticPreferencesInitializer.java').includes('implements g06'));
t('search AppSearch generated $$__', has('search/C$$__AppSearch__SearchResult.java'));
t('SearchResult record', R('search/SearchResult.java').includes('SearchResult(int i, String str'));
t('SearchDatabase + SearchIndexDatabase', has('search/database/SearchDatabase.java') && has('search/engine/room/SearchIndexDatabase.java'));
console.log('data-repos replay: ' + n + '/10 checks green');
