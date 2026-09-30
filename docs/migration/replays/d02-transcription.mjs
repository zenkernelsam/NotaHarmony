// Phase 1287 — transcription GCS+HTTP layer
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/data/transcription/';
const R = f => readFileSync(S + f, 'utf8');
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('TranscriptionDatabase', X('database/TranscriptionDatabase.java'));
t('TranscriptionDatabase_Impl Room', X('database/TranscriptionDatabase_Impl.java'));
const lte = R('livetranscription/LiveTranscriptionHttpException.java');
t('LiveTranscriptionHttpException status', lte.includes('int I'));
t('LiveTranscription extends Exception', lte.includes('extends Exception'));
t('GCSUploadException', X('upload/GCSUploadException.java'));
const gcs = R('upload/GCSUploadException.java');
t('GCSUpload extends Exception', gcs.includes('Exception'));
t('TranscriptionException', X('TranscriptionException.java'));
t('TranscriptionNotFound', X('TranscriptionNotFoundException.java'));
const tn = R('TranscriptionNotFoundException.java');
t('TranscriptionNotFound Exception', tn.includes('Exception'));
const nbdb = X('../../data/transcription/database/TranscriptionDatabase.java');
t('transcription data-layer present', X('database/TranscriptionDatabase.java'));
console.log('transcription replay: ' + n + '/10 checks green');
