import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(path.join(root, 'note/src/main/ets/core/adaptation/ImageAssetLoader.ets'), 'utf8');
const checks = [
  ['width is safe positive integer', source.includes('Number.isSafeInteger(info.size.width)') && source.includes('info.size.width <= 0')],
  ['height is safe positive integer', source.includes('Number.isSafeInteger(info.size.height)') && source.includes('info.size.height <= 0')],
  ['invalid dimensions fail explicitly', source.includes('asset image dimensions are invalid')],
  ['validation precedes maximum calculation', source.indexOf('asset image dimensions are invalid') < source.indexOf('const maximum: number')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
