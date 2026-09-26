// Phase 841 — core/ 包叶子面（异常族 + glmath JNI）
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/com/gingerlabs/notability/core';
const read = (p) => readFileSync(join(S, p), 'utf8');

const results = [];
const ck = (n, ok) => results.push([n, ok]);

// 异常族存在
for (const [pkg, cls] of [
  ['network', 'HttpStatusException'], ['network', 'NoConnectivityException'], ['network', 'NotAuthenticatedException'],
  ['retrofit', 'HttpFailureException'], ['analytics', 'NbPerformance$SpanAborted'],
  ['common/logging', 'NbLog$FatalLogError'], ['common/logging', 'FirebaseLogger$LoggedError'],
  ['common/memory', 'SharedMemoryByteArena$ArenaClosedException'], ['model', 'CopyPasteException'],
]) {
  const f = join(S, pkg, cls + '.java');
  let ok = false;
  try { ok = readFileSync(f, 'utf8').includes('extends'); } catch {}
  ck(`异常类 ${pkg}/${cls}`, ok);
}

// glmath JNI
const gl = read('glmath/GLMathNative.java');
ck('loadLibrary glmath', gl.includes('System.loadLibrary("glmath")'));
ck('nativeInit', gl.includes('nativeInit'));
ck('nativeMeasure', gl.includes('nativeMeasure'));
ck('nativeDraw', gl.includes('nativeDraw'));
ck('nativeSearchText', gl.includes('nativeSearchText'));
ck('MathDrawTarget 接口', read('glmath/MathDrawTarget.java').length > 0);
ck('GLMathTextMeasurer', read('glmath/GLMathTextMeasurer.java').length > 0);

// Harmony 侧
const moe = readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/ui/components/MathEditorOverlay.ets', 'utf8');
ck('Harmony 数学=PixelMap 预览', moe.includes('PixelMap'));
ck('Harmony 无原生 LaTeX 引擎', !moe.includes('nativeDraw') && !moe.includes('nativeMeasure'));

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
