// Phase 1226 — ML Kit client/AIDL layer
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const o23 = R('o23.java');
t('o23 DecoupledTextDelegate', o23.includes('DecoupledTextDelegate'));
t('o23 thick/thin OCR fallback', o23.includes('thick OCR module') && o23.includes('thin OCR module'));
t('o23 latin module config', o23.includes('optional-module-text-latin') && o23.includes('DynamiteModule'));
const mc1 = R('mc1.java');
t('mc1 GmsDocumentScannerImpl', mc1.includes('GmsDocumentScannerImpl'));
t('mc1 ACTION_SCAN_DOCUMENT GMS intent', mc1.includes('com.google.android.gms.mlkit.ACTION_SCAN_DOCUMENT') && mc1.includes('setPackage("com.google.android.gms")'));
t('mc1 resolveActivity gate', mc1.includes('resolveActivity'));
const re = R('re.java');
t('re IDocumentScannerService AIDL', re.includes('IDocumentScannerService'));
t('p4h IDocumentScannerCallbacks', R('p4h.java').includes('IDocumentScannerCallbacks'));
t('hhj ITextRecognizer AIDL', R('hhj.java').includes('ITextRecognizer'));
t('ztg VkpTextRecognizerOptions', R('ztg.java').includes('VkpTextRecognizerOptions'));
console.log('mlkit-clients replay: ' + n + '/10 checks green');
