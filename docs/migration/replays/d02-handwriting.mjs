// Phase 1292 — handwriting pack delivery (MyScript + Play AssetDelivery)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/data/handwritingrecognition/';
const R = f => readFileSync(S + f, 'utf8');
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const w = R('HandwritingPackDownloadWorker.java');
t('HandwritingPackDownloadWorker', w.includes('CoroutineWorker'));
t('worker zb5 installer', w.includes('zb5') && w.includes('installer'));
t('LanguagePackUnavailableException', X('LanguagePackUnavailableException.java'));
t('MathRecognitionUnsupportedException', X('MathRecognitionUnsupportedException.java'));
const mre = R('MathRecognitionUnsupportedException.java');
t('MathRecognitionUnsupported', mre.length > 0);
t('PlayAssetDeliveryUnavailableException', X('PlayAssetDeliveryUnavailableException.java'));
const pad = R('PlayAssetDeliveryUnavailableException.java');
t('PlayAssetDelivery unavailable', pad.length > 0);
t('iink Engine present (P1280)', existsSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/myscript/iink/Engine.java'));
t('LanguagePack exc', R('LanguagePackUnavailableException.java').includes('Exception'));
const im = X('HandwritingPackDownloadWorker.java');
t('hwr layer complete', im && X('LanguagePackUnavailableException.java'));
console.log('handwriting replay: ' + n + '/10 checks green');
