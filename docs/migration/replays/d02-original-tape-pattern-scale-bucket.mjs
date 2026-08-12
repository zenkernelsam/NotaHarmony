import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/core/adaptation/Canvas2DStrokeRenderer.ets'), 'utf8');
const checks = [
  ['render passes Tape brush width', source.includes('0xFFFFFFFF, stroke.renderSpec.brushWidth')],
  ['width is bounded to original range', source.includes('Math.min(8, Math.max(1, brushWidth))')],
  ['bucket uses original doubled rounding', source.includes('Math.round(boundedWidth * 2)')],
  ['bucket is part of cache identity', source.includes('`${pattern}:${overlayColor}:${colorKey}:${scaleBucket}`')],
  ['logical tile size follows bucket', source.includes('size.width * scaleFactor') && source.includes('size.height * scaleFactor')],
  ['FLOWERS remains the only tape-color variant', source.includes('pattern === TapePattern.FLOWERS ? tapeColor : 0')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
