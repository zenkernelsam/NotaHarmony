// Phase 1175 — ink input layer (MultiPointerPredictor + gesture-classification + OnTouchListener)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const bi8 = R('bi8.java');
t('bi8 MultiPointerPredictor tag', bi8.includes('MultiPointerPredictor'));
t('bi8 SparseArray per-pointer', bi8.includes('SparseArray'));
t('bi8 a(MotionEvent)+b(int) predict', bi8.includes('a(MotionEvent') && bi8.includes('MotionEvent b('));
const mf8 = R('mf8.java');
t('mf8 predictor iface a+b', mf8.includes('interface mf8') && mf8.includes('a(MotionEvent') && mf8.includes('MotionEvent b('));
t('tl6 implements mf8', R('tl6.java').includes('implements mf8'));
const iqa = R('iqa.java');
t('iqa uses getClassification', iqa.includes('getClassification'));
t('iqa buttonState+metaState', iqa.includes('getButtonState') && iqa.includes('getMetaState'));
t('iqa actionMasked dispatch', iqa.includes('getActionMasked'));
t('iqa classification 3/5 gesture', iqa.includes('getClassification() == 3') && iqa.includes('getClassification() == 5'));
t('cj7 OnTouchListener + TapTimeout', R('cj7.java').includes('implements View.OnTouchListener') && R('cj7.java').includes('getTapTimeout'));
console.log('ink-input replay: ' + n + '/10 checks green');
