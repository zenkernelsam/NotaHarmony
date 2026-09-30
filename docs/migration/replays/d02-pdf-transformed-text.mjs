// Phase 1215 — pdf = TransformedTextFieldState
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const pdf = R('pdf.java');
t('pdf toString TransformedTextFieldState', pdf.includes('TransformedTextFieldState'));
t('pdf textFieldState=qoe', pdf.includes('textFieldState='));
t('pdf outputTransformation', pdf.includes('outputTransformation='));
t('pdf codepointTransformation', pdf.includes('codepointTransformation='));
t('pdf outputText/visualText', pdf.includes('outputText=') && pdf.includes('visualText='));
t('pdf d()->ele output', pdf.includes('ele d()'));
t('pdf f()->ele visual', pdf.includes('ele f()'));
t('pdf offset map g/h/i', pdf.includes('long g(int') && pdf.includes('long h(long') && pdf.includes('long i(long'));
t('pdf commit qoe.a+f(true)', pdf.includes('qoe.a(qoeVar') && pdf.includes('qoeVar.f(true)'));
t('na3 extends osd MutableState', R('na3.java').includes('extends osd'));
console.log('pdf-transformed-text replay: ' + n + '/10 checks green');
