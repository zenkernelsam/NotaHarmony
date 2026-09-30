// Phase 1170 — data/handwritingrecognition (iink pack delivery via Play Asset Delivery)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const B = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/data/handwritingrecognition/';
const has = f => existsSync(B + f);
const R = f => readFileSync(B + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const worker = R('HandwritingPackDownloadWorker.java');
t('HandwritingPackDownloadWorker exists', has('HandwritingPackDownloadWorker.java'));
t('Worker extends CoroutineWorker', worker.includes('extends CoroutineWorker'));
t('Worker has Context+WorkerParameters ctor', worker.includes('WorkerParameters'));
t('Worker suspend doWork b(ef2)', worker.includes('b(ef2'));
t('LanguagePackUnavailableException exists', has('LanguagePackUnavailableException.java'));
t('LanguagePackUnavailableException(dc5) + getI', R('LanguagePackUnavailableException.java').includes('LanguagePackUnavailableException(dc5') && R('LanguagePackUnavailableException.java').includes('getI'));
t('MathRecognitionUnsupportedException exists', has('MathRecognitionUnsupportedException.java') && R('MathRecognitionUnsupportedException.java').includes('extends Exception'));
t('PlayAssetDeliveryUnavailableException exists', has('PlayAssetDeliveryUnavailableException.java'));
t('PlayAssetDeliveryUnavailableException extends IOException', R('PlayAssetDeliveryUnavailableException.java').includes('extends IOException'));
t('PlayAssetDeliveryUnavailableException(String,Throwable) ctor', R('PlayAssetDeliveryUnavailableException.java').includes('Throwable'));
console.log('handwriting replay: ' + n + '/10 checks green');
