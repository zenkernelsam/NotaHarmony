import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(path.join(root, 'note/src/main/ets/core/algorithm/CubicFitter.ets'), 'utf8');
const checks = [
  ['max segment count requires finite integer >= 2', source.includes('Number.isInteger(config.maxPointsPerSegment)') && source.includes('config.maxPointsPerSegment >= 2')],
  ['context expansion requires finite integer >= 0', source.includes('Number.isInteger(config.contextExpansion)') && source.includes('config.contextExpansion >= 0')],
  ['base tolerance requires finite positive value', source.includes('config.baseTolerance > 0')],
  ['defaults remain original values', source.includes('maxPointsPerSegment: 200') && source.includes('contextExpansion: 5') && source.includes('baseTolerance: 0.5')],
  ['dynamic original tolerance formula remains used', source.includes('return computeOriginalFitTolerance(baseWidth, zoom);')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
