import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/core/adaptation/Canvas2DStrokeRenderer.ets'), 'utf8');
const checks = [
  ['Tape renderer does not misuse brush width as zoom', !source.includes('0xFFFFFFFF, stroke.renderSpec.brushWidth')],
  ['current cache key remains color-correct', source.includes('`${pattern}:${overlayColor}:${colorKey}`')],
  ['FLOWERS remains the only tape-color variant', source.includes('pattern === TapePattern.FLOWERS ? tapeColor : 0')],
  ['zoom gap is documented', fs.readFileSync(path.join(root, 'docs/migration/adr/ADR-0132-original-tape-pattern-scale-bucket.md'), 'utf8').includes('zoom')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
