import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/core/adaptation/InkInputProviderImpl.ets'), 'utf8');
const checks = [
  ['timestamp requires finite value', source.includes('Number.isFinite(raw.timestamp)')],
  ['pressure rejects non-finite values', source.includes('Number.isFinite(raw.pressure)')],
  ['tilt rejects non-finite values', source.includes('Number.isFinite(raw.tiltRadians)')],
  ['orientation rejects non-finite values', source.includes('Number.isFinite(raw.orientationRadians)')],
  ['pressure invalid sentinel remains -1', source.includes(': -1,')],
  ['orientation still uses normalized finite path', source.includes('this.normalizeOrientation(raw.orientationRadians)')],
  ['tool mapping remains intact', source.includes('this.mapToolType(raw.toolType)')],
  ['historical/predicted classification remains intact', source.includes('InputBatchKind.HISTORICAL') && source.includes('InputBatchKind.PREDICTED')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);

