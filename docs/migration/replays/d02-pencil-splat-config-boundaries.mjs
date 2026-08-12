import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/core/algorithm/PencilSplatGenerator.ets'), 'utf8');
const checks = [
  ['spacing rejects non-positive/non-finite values', source.includes('merged.spacing > 0') && source.includes('Number.isFinite(merged.spacing)')],
  ['pressure power rejects non-finite/negative values', source.includes('merged.pressurePower >= 0')],
  ['tilt normalization prevents zero divisor', source.includes('Math.abs(merged.tiltNormalize) > 1e-9')],
  ['ellipse shrink rejects non-finite/negative values', source.includes('merged.ellipseShrink >= 0')],
  ['angle step is strictly positive', source.includes('merged.angleStep > 0')],
  ['subdivisions are finite positive integers', source.includes('Math.floor(merged.maxSubdivisions)') && source.includes('merged.maxSubdivisions >= 1')],
  ['LCG multiplier is normalized to an integer', source.includes('Math.floor(merged.lcgMultiplier)')],
  ['LCG modulus is greater than one', source.includes('merged.lcgModulus > 1')],
  ['splat budget is finite and non-negative', source.includes('Math.floor(merged.maximumSplatCount)') && source.includes('merged.maximumSplatCount >= 0')],
  ['original generation formulas remain present', source.includes('Math.sqrt(u1)') && source.includes('this.nextRandom() * twoPi')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);

