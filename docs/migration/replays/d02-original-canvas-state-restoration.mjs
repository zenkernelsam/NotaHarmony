import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = process.env.NOTABILITY_ORIGINAL_ROOT ??
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';

function readRepo(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), 'utf8');
}

function readOriginal(fileName) {
  return fs.readFileSync(path.join(originalRoot, fileName), 'utf8');
}

function unguardedSaveLines(source) {
  const lines = source.split(/\r?\n/);
  const failures = [];
  for (let index = 0; index < lines.length; index++) {
    const line = lines[index];
    if (!line.includes('.save();') || line.includes('this.ctx.save();')) {
      continue;
    }
    let next = index + 1;
    while (next < lines.length && lines[next].trim().length === 0) {
      next++;
    }
    if (next >= lines.length || lines[next].trim() !== 'try {') {
      failures.push(index + 1);
    }
  }
  return failures;
}

const guardedFiles = [
  'note/src/main/ets/core/adaptation/Canvas2DStrokeRenderer.ets',
  'note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets',
  'note/src/main/ets/rendering/ImageCanvasRenderer.ets',
  'note/src/main/ets/rendering/MathCanvasRenderer.ets',
  'note/src/main/ets/rendering/PaperRenderer.ets',
  'note/src/main/ets/rendering/ShapeCanvasRenderer.ets',
  'note/src/main/ets/rendering/StrokeCanvasPainter.ets',
  'note/src/main/ets/rendering/StrokeLayerManager.ets',
  'note/src/main/ets/rendering/ThumbnailRenderer.ets',
  'note/src/main/ets/ui/editor/NoteCanvasView.ets',
];

const c5g = readOriginal('c5g.java');
const v0g = readOriginal('v0g.java');
const dirty = readRepo('note/src/main/ets/rendering/DirtyRectTracker.ets');
const strokePainter = readRepo('note/src/main/ets/rendering/StrokeCanvasPainter.ets');
const layerManager = readRepo('note/src/main/ets/rendering/StrokeLayerManager.ets');

const checks = [
  ['original splat path restores saved canvas in finally',
    /int iSave = canvas\.save\(\);[\s\S]{0,500}finally \{[\s\S]{0,120}canvas\.restoreToCount\(iSave\)/.test(c5g)],
  ['original path renderer restores saved canvas in finally',
    /Paint paint3 = this\.g;[\s\S]{0,120}int iSave = canvas\.save\(\);[\s\S]{0,500}finally \{[\s\S]{0,120}canvas\.restoreToCount\(iSave\)/.test(c5g)],
  ['original tape renderer restores saved canvas on success and failure',
    /qfeVar\.a\([\s\S]{0,140}canvas\.restoreToCount\(iSave\);[\s\S]{0,120}catch \(Throwable th\)[\s\S]{0,100}canvas\.restoreToCount\(iSave\)/.test(c5g)],
  ['original persisted viewport rejects non-finite zoom',
    v0g.includes('Math.abs(f.floatValue()) <= Float.MAX_VALUE') &&
      v0g.includes('Discarding corrupt persisted viewport zoom')],
  ['dirty padding rejects non-finite zoom',
    dirty.includes('Number.isFinite(zoom) && zoom > 0 ? zoom : 1')],
  ['isolated stroke bitmap closes in finally',
    /transferToImageBitmap\(\);[\s\S]{0,160}try \{[\s\S]{0,220}finally \{[\s\S]{0,80}bitmap\.close\(\)/.test(strokePainter)],
  ['ordered partial eraser bitmap closes in finally',
    /transferToImageBitmap\(\);[\s\S]{0,180}try \{[\s\S]{0,240}finally \{[\s\S]{0,80}bitmap\.close\(\)/.test(layerManager)],
];

for (const relativePath of guardedFiles) {
  const failures = unguardedSaveLines(readRepo(relativePath));
  checks.push([`${relativePath} guards every rendering save`, failures.length === 0]);
}

for (const [name, ok] of checks) {
  if (!ok) {
    throw new Error(`FAILED: ${name}`);
  }
  console.log(`PASS: ${name}`);
}
console.log(`D02_ORIGINAL_CANVAS_STATE_RESTORATION_OK TOTAL=${checks.length} FAILED=0`);
