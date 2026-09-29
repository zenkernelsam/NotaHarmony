// Phase 1120 — glmath native bridge + MathDrawTarget + text measurer
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const G = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/core/glmath/';
const R = f => readFileSync(G + f, 'utf8');
const nat = R('GLMathNative.java'), tgt = R('MathDrawTarget.java'), msr = R('GLMathTextMeasurer.java');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('GLMathNative loadLibrary glmath', nat.includes('loadLibrary("glmath")'));
t('nativeInit(resPath)→bool', nat.includes('nativeInit(String resPath)') && nat.includes('native boolean'));
t('nativeMeasure(latex,w,fs)→float[]', nat.includes('nativeMeasure(String latex, float width, float fontSize)') && nat.includes('float[]'));
t('nativeDraw + MathDrawTarget arg', nat.includes('nativeDraw') && nat.includes('MathDrawTarget'));
t('MathDrawTarget wraps Canvas', tgt.includes('MathDrawTarget(Canvas'));
t('draw primitives: line/rect/round', tgt.includes('drawLine(') && tgt.includes('drawRect(') && tgt.includes('drawRoundRect('));
t('drawText(text,x,y,fontFile,style,size)', tgt.includes('drawText(String text'));
t('fillRect present', tgt.includes('fillRect('));
t('measurer → float[]{w,ascent,descent}', msr.includes('measureText(text)') && msr.includes('fontMetrics.ascent') && msr.includes('fontMetrics.descent'));
t('measurer Paint+lz4 typeface', msr.includes('new Paint(') && msr.includes('lz4.a.a(fontStyle, fontFile)'));
console.log('glmath replay: ' + n + '/10 checks green');
