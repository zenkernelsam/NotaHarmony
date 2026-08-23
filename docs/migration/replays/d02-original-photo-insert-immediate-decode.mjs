import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8').replaceAll('\r\n', '\n');
const evidence = fs.readFileSync(
  'docs/migration/evidence/photo-insert-runtime-decode-gap-harmony-2026-08-23.md', 'utf8');

const insert = canvas.indexOf('private async insertOriginalPhotos');
const next = canvas.indexOf('private async confirmMathInsert', insert);
const source = canvas.slice(insert, next);
const install = source.indexOf('this.imageBlocks = this.imageBlocks.concat(finalImages);');
const refresh = source.indexOf('this.refreshImageAssets(generation, pageId);');
const order = source.indexOf('this.elementOrder = clonePageElementOrder(finalOrder);');
const render = source.indexOf('this.renderFrame();');

const checks = [
  ['new blocks are installed on the live page',
    install >= 0 && source.includes('if (this.isHistoryPageContextCurrent(generation, pageId)) {')],
  ['decode cache is refreshed immediately after installation',
    install >= 0 && refresh > install],
  ['refresh precedes order synchronization and first render',
    refresh >= 0 && order > refresh && render > order],
  ['refresh uses the captured page generation and page identity',
    source.includes('this.refreshImageAssets(generation, pageId);')],
  ['async loader retains stale-generation release guard',
    canvas.includes('assetGeneration !== this.imageAssetGeneration || this.loadedPageId !== pageId') &&
    canvas.includes('loader.release(loaded);')],
  ['availability callback still guards against foreign arrivals',
    canvas.includes('originalAssetStorageHash(block.assetHashBits) === change.storageHash') &&
    canvas.includes('this.refreshImageAssets(this.pageLoadGeneration, this.loadedPageId);')],
  ['evidence explains why the self publish event could not rescue first frame',
    evidence.includes('发布发生在 caller 安装 `imageBlocks`') &&
    evidence.includes('无法命中新 block') &&
    evidence.includes('重启后才显示')],
];

let failed = 0;
for (const [name, passed] of checks) {
  console.log(`${passed ? 'PASS' : 'FAIL'} ${name}`);
  if (!passed) failed++;
}
console.log(`D02_ORIGINAL_PHOTO_INSERT_IMMEDIATE_DECODE_OK TOTAL=${checks.length} FAILED=${failed}`);
if (failed > 0) process.exitCode = 1;
