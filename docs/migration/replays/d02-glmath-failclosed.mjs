// Phase 1168 — libglmath fail-closed mechanism (kd guard + MissingNativeLibrary)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
const kd = readFileSync(S + 'defpackage/kd.java', 'utf8');
const mnla = readFileSync(S + 'com/gingerlabs/notability/app/MissingNativeLibraryActivity.java', 'utf8');
const gn = readFileSync(S + 'com/gingerlabs/notability/core/glmath/GLMathNative.java', 'utf8');
const asi = readFileSync(S + 'com/gingerlabs/notability/app/initializers/AppStartupInitializer.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('libglmath.so arm64 exists', existsSync('C:/Users/Cisco He/Desktop/Notability/arm64_extracted/lib/arm64-v8a/libglmath.so'));
t('GLMathNative loadLibrary("glmath")', gn.includes('loadLibrary("glmath")'));
t('GLMathNative catches UnsatisfiedLinkError', gn.includes('UnsatisfiedLinkError'));
t('kd launches MissingNativeLibraryActivity', kd.includes('MissingNativeLibraryActivity.class'));
t('kd flags NEW_TASK|CLEAR (268468224)', kd.includes('addFlags(268468224)'));
t('kd main-looper startActivity', kd.includes('Looper.getMainLooper()') && kd.includes('startActivity'));
t('MNLA un-cancelable AlertDialog', mnla.includes('AlertDialog.Builder') && mnla.includes('setCancelable(false)'));
t('MNLA missing_native_library strings', mnla.includes('app__missing_native_library_title') && mnla.includes('app__missing_native_library_message'));
t('MNLA OK button exits', mnla.includes('setPositiveButton'));
t('AppStartupInitializer catches UnsatisfiedLinkError', asi.includes('UnsatisfiedLinkError'));
console.log('glmath-failclosed replay: ' + n + '/10 checks green');
