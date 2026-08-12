import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(path.join(root, 'note/src/main/ets/data/BinaryPlistParser.ets'), 'utf8');
const baseBranch = source.indexOf('if (low === 0xD)');
const baseRead = source.indexOf('const baseRef: number', baseBranch);
const baseResolve = source.indexOf('this.objectAt(baseRef, depth + 1)', baseRead);
const stringRead = source.indexOf('const stringRefOffset: number', baseResolve);
const checks = [
  ['URL-with-base has a dedicated base branch', baseBranch >= 0],
  ['base reference is read with object reference size',
    source.includes('uintBE(this.data, pos + 1, this.refSize)')],
  ['base reference is resolved through the object graph', baseResolve > baseRead],
  ['invalid base fails explicitly', source.includes("this.fail('URL-with-base 的 base 引用无效')")],
  ['base is validated before URL string', baseBranch < baseRead && baseRead < baseResolve && baseResolve < stringRead],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
