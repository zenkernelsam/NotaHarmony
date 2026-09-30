// Phase 1203 — androidx.ink dependency boundary
import { readFileSync, readdirSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
const D = S + 'defpackage/';
const R = f => readFileSync(S + f, 'utf8');
const walk = d => readdirSync(S + d, { recursive: true }).map(f => f.replace(/\\/g, '/')).filter(f => f.endsWith('.java'));
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const inkFiles = walk('androidx/ink');
t('androidx.ink ~57 files', inkFiles.length >= 50);
t('brush package exists', inkFiles.some(f => f.startsWith('brush/')));
t('brush.behavior node graph ~12 natives', inkFiles.filter(f => f.startsWith('brush/behavior/')).length >= 10);
t('geometry natives', inkFiles.filter(f => f.startsWith('geometry/')).length >= 10);
t('strokes StrokeInput', inkFiles.some(f => f === 'strokes/StrokeInput.java'));
t('nativeloader UsedByNative', inkFiles.some(f => f === 'nativeloader/UsedByNative.java'));
// defpackage usage census
const dep = readdirSync(D).filter(f => f.endsWith('.java'));
let used = 0, si = 0, batch = 0, box = 0;
for (const f of dep) {
  const s = readFileSync(D + f, 'utf8');
  if (!s.includes('androidx.ink')) continue;
  used++;
  if (s.includes('androidx.ink.strokes.StrokeInput')) si++;
  if (s.includes('StrokeInputBatchNative')) batch++;
  if (s.includes('androidx.ink.geometry')) box++;
}
t('~26 defpackage files use ink', used >= 20);
t('StrokeInput used ~9', si >= 8);
t('batch natives used', batch >= 5);
t('geometry used', box >= 10);
console.log('androidx-ink replay: ' + n + '/10 checks green');
