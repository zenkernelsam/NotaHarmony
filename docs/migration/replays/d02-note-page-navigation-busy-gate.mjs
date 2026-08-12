import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/ui/editor/NotePage.ets'), 'utf8');
const prev = source.indexOf('onPrev: () =>');
const next = source.indexOf('onNext: () =>');
const nextSection = source.indexOf('onAdd: () =>', next);
const checks = [
  ['prev callback exists', prev >= 0],
  ['next callback exists', next > prev],
  ['prev has loading and operation gate',
    source.slice(prev, next).includes('!this.pageLoading') &&
      source.slice(prev, next).includes('!this.pageOperationBusy')],
  ['next has loading and operation gate',
    source.slice(next, nextSection).includes('!this.pageLoading') &&
      source.slice(next, nextSection).includes('!this.pageOperationBusy')],
  ['prev retains lower bound', source.slice(prev, next).includes('this.currentPageIndex > 0')],
  ['next retains upper bound', source.slice(next, nextSection).includes('this.pages.length - 1')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
