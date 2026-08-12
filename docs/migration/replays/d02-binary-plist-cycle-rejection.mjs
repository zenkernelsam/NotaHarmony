import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(path.join(root, 'note/src/main/ets/data/BinaryPlistParser.ets'), 'utf8');
const checks = [
  ['cycle branch exists', source.includes('if (this.visiting.has(index))')],
  ['cycle sets parser error', source.includes('this.fail(`检测到循环对象引用 index=${index}`)')],
  ['cycle returns failure null', source.includes('this.fail(`检测到循环对象引用 index=${index}`);\n      return null;')],
  ['legacy null placeholder removed', !source.includes('已用 null 占位')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
