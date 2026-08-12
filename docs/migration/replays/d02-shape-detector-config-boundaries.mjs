import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/core/algorithm/ShapeDetector.ets'), 'utf8');
const checks = [
  ['line threshold is finite and non-negative', source.includes('Number.isFinite(merged.lineThreshold)') && source.includes('merged.lineThreshold >= 0')],
  ['line length is finite and non-negative', source.includes('Number.isFinite(merged.lineMinLength)') && source.includes('merged.lineMinLength >= 0')],
  ['ellipse gap is finite and non-negative', source.includes('Number.isFinite(merged.ellipseMaxGap)') && source.includes('merged.ellipseMaxGap >= 0')],
  ['refit threshold is strictly positive', source.includes('Number.isFinite(merged.refitThreshold)') && source.includes('merged.refitThreshold > 0')],
  ['confidence threshold is bounded', source.includes('merged.confidenceThreshold >= 0') && source.includes('merged.confidenceThreshold <= 1')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
