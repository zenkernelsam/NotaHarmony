// Phase 1059 — ee8 PDF field + ua0 AssetHash + sw9 PDFAsset + wa0
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const ee8 = R('ee8'), ua0 = R('ua0'), sw9 = R('sw9'), wa0 = R('wa0');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ee8 ModifyPDFField 5 fields', ee8.includes('ModifyPDFField(assetHash=') && ee8.includes('key=') && ee8.includes('valueType=') && ee8.includes('valueString=') && ee8.includes('valueBoolean='));
t('ee8: assetHash→ua0, valueType→ww9', ee8.includes('ua0 j()') && ee8.includes('ww9 n()'));
t('ee8: string/bool nil checks', ee8.includes('Type is string but the string is nil') && ee8.includes('Type is bool but the bool is nil'));
t('ua0: 8×long AssetHash', (ua0.match(/getLong\(this\.I \+ \d+\)/g) || []).length >= 7 && ua0.includes('bits0=') && ua0.includes('bits7='));
t('ua0: 64-byte struct (xwd)', ua0.includes('extends xwd') && ua0.includes('AssetHash(bits0='));
t('sw9 PDFAsset fields', sw9.includes('PDFAsset(metadata=') && sw9.includes('layoutBehavior=') && sw9.includes('totalPageCount=') && sw9.includes('pagesConsumed=') && sw9.includes('pageOffset=') && sw9.includes('cropBoxes='));
t('sw9: metadata→wa0, layout→xw9', sw9.includes('wa0 m()') && sw9.includes('xw9 l()'));
t('sw9: cropBoxes qed vector', sw9.includes('j(int i, qed qedVar)') && sw9.includes('lv2.v(this)'));
t('sw9: 3 int accessors n/o/p', (sw9.match(/public final int [n-p]\(\)/g) || []).length === 3);
t('wa0: size/mime/name validation', wa0.includes('Asset file size must be larger than 0') && wa0.includes('Asset mime type must not be empty') && wa0.includes('Asset file name must not be empty'));
t('ee8/sw9/ua0 cee-or-xwd + ka4', [ee8, sw9, ua0].every(s => (s.includes('extends cee') || s.includes('extends xwd')) && s.includes('implements ka4')));
t('ua0: njj.j0 fmt bits', ua0.includes('njj.j0(10, c())'));
console.log('pdf-asset-hash replay: ' + n + '/12 checks green');
