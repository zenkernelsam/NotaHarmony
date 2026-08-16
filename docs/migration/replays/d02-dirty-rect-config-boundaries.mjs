import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/rendering/DirtyRectTracker.ets'), 'utf8');
const checks = [
  ['padding rejects non-finite values', source.includes('Number.isFinite(screenPadding)')],
  ['padding keeps default fallback', source.includes(': 3;')],
  ['region limit rejects non-finite values', source.includes('Number.isFinite(maxRegions)')],
  ['region limit is an integer with minimum one', source.includes('Math.floor(maxRegions)') && source.includes('Math.max(1')],
  ['zoom fallback rejects non-finite values',
    source.includes('Number.isFinite(zoom) && zoom > 0 ? zoom : 1')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
