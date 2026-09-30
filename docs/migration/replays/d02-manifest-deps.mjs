// Phase 1227 — manifest dependency census (GMS/Firebase/Play)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const M = readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/AndroidManifest.xml','utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('Firebase crashlytics', M.includes('crashlytics'));
t('Firebase perf+remoteconfig', M.includes('perf.FirebasePerf') && M.includes('remoteconfig'));
t('Firebase sessions+installations', M.includes('FirebaseSessionsRegistrar') && M.includes('installations'));
t('AppMeasurement GA4', M.includes('measurement.AppMeasurement'));
t('datatransport CCT', M.includes('datatransport'));
t('Google Sign-In', M.includes('auth.api.signin'));
t('Play billingclient', M.includes('billingclient'));
t('Play assetpacks', M.includes('assetpacks'));
t('ML Kit registrars', M.includes('mlkit.common.internal.MlKitInitProvider') || M.includes('MlKitInitProvider'));
t('GmsDocumentScanningDelegateActivity', M.includes('GmsDocumentScanningDelegateActivity'));
console.log('manifest-deps replay: ' + n + '/10 checks green');
