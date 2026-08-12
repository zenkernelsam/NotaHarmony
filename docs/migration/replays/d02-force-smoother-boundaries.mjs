import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(path.join(root, 'note/src/main/ets/core/algorithm/ForceSmoother.ets'), 'utf8');
const checks = [
  ['time weighted smoothing remains', source.includes('dt / this.config.smoothingWindowMs')],
  ['invalid window falls back', source.includes('merged.smoothingWindowMs = 8')],
  ['invalid change limit falls back', source.includes('merged.maxForceChange = 0.15')],
  ['non-finite pressure is not persisted', source.includes('!Number.isFinite(p.pressure)')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
