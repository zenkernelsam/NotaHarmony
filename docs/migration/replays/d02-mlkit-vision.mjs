// Phase 1225 — ML Kit Vision dependency (TextRecognizer + DocumentScanner)
import { readFileSync, readdirSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
const D = S + 'defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('TextRecognizer used (hhj/ztg/qyg)', ['hhj','ztg','qyg'].every(f=>R(f+'.java').includes('TextRecognizer')));
t('DocumentScanner used (re/p4h)', ['re','p4h'].every(f=>R(f+'.java').includes('DocumentScanner')));
t('GmsDocumentScanningDelegateActivity', readFileSync(S+'com/google/mlkit/vision/documentscanner/internal/GmsDocumentScanningDelegateActivity.java','utf8').includes('GmsDocumentScanningDelegateActivity extends'));
const vision = readdirSync(S+'com/google/mlkit/vision',{recursive:true}).map(f=>f.replace(/\\/g,'/'));
t('vision.documentscanner pkg', vision.some(f=>f.includes('documentscanner/')));
t('vision.text bundled', vision.some(f=>f.includes('text/')));
const common = readdirSync(S+'com/google/mlkit/common',{recursive:true});
t('MlKitInitProvider+Discovery', common.some(f=>f.includes('MlKitInitProvider')) && common.some(f=>f.includes('MlKitComponentDiscoveryService')));
t('MlKitException', common.some(f=>f.includes('MlKitException')));
const bundled = readdirSync(S+'com/google/android/gms/internal/mlkit_vision_text_bundled_common',{recursive:true});
t('bundled latin model files', bundled.length>=5);
t('dynamite latin descriptor', readFileSync(S+'com/google/android/gms/dynamite/descriptors/com/google/mlkit/dynamite/text/latin/ModuleDescriptor.java','utf8').includes('latin'));
t('visionkit pipeline native', readFileSync(S+'com/google/android/libraries/vision/visionkit/pipeline/alt/NativePipelineImpl.java','utf8').includes('NativePipeline'));
console.log('mlkit-vision replay: ' + n + '/10 checks green');
