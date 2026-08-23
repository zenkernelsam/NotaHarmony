import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8').replaceAll('\r\n', '\n');
const base = JSON.parse(fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8'));
const zh = JSON.parse(fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8'));
const fixture = fs.readFileSync('note/src/test/OriginalPhotoHistoryMetadata.test.ets', 'utf8');
const fixtureList = fs.readFileSync('note/src/test/List.test.ets', 'utf8');

function hasValue(json, name, value) {
  return json.string.some((entry) => entry.name === name && entry.value === value);
}

const start = canvas.indexOf('private async startOriginalPhotoInsert');
const commit = canvas.indexOf('private async commitOriginalPhotoInsert');
const insert = canvas.indexOf('private async insertOriginalPhotos');
const nextMethod = canvas.indexOf('private async confirmMathInsert', insert);
const startSource = canvas.slice(start, commit);
const commitSource = canvas.slice(commit, insert);
const insertSource = canvas.slice(insert, nextMethod);

const checks = [
  ['start path receives an explicit success-prefix count',
    commitSource.includes('return this.insertOriginalPhotos(imported);') &&
    startSource.includes('const outcome: PhotoInsertOutcome = await this.commitOriginalPhotoInsert(imported);')],
  ['partial failure shows explicit feedback without save-failure state',
    startSource.includes("message: $r('app.string.original_photo_insert_partial_failed')") &&
    insertSource.includes('partialFailure = true;') &&
    insertSource.includes('!partialFailure) {') &&
    insertSource.includes('this.saveFailed = false;')],
  ['photo feedback toasts stay bound to the originating page',
    startSource.includes('const photoGeneration: number = this.pageLoadGeneration;') &&
    startSource.includes('const photoPageId: string = this.loadedPageId;') &&
    startSource.indexOf('photoGeneration === this.pageLoadGeneration &&\n        photoPageId === this.loadedPageId &&\n        outcome.insertedCount < outcome.totalCount') <
      startSource.indexOf("$r('app.string.original_photo_insert_partial_failed')") &&
    startSource.lastIndexOf('if (photoGeneration === this.pageLoadGeneration &&\n        photoPageId === this.loadedPageId) {') <
      startSource.indexOf("$r('app.string.original_photo_insert_failed')")],
  ['successful prefix cannot clear a foreign page save state',
    insertSource.includes('if (this.isHistoryPageContextCurrent(generation, pageId) && !partialFailure) {') &&
    insertSource.indexOf('if (this.isHistoryPageContextCurrent(generation, pageId) && !partialFailure) {') <
      insertSource.indexOf('this.saveFailed = false;')],
  ['first-image failure remains whole-batch failed',
    insertSource.includes('if (results.length === 0) {') &&
    insertSource.includes("throw new Error('original photo insert commit failed');") &&
    startSource.includes("message: $r('app.string.original_photo_insert_failed')")],
  ['save-failure feedback stays bound to the inserting page',
    insertSource.includes('if (this.isHistoryPageContextCurrent(generation, pageId)) {') &&
    insertSource.lastIndexOf('if (this.isHistoryPageContextCurrent(generation, pageId)) {') <
      insertSource.lastIndexOf('this.reportSaveFailure(e as Object);')],
  ['each image keeps its own durable transaction boundary',
    (insertSource.match(/commitOriginalImageInsert\(/g) || []).length === 1 &&
    insertSource.includes('break;')],
  ['success prefix is installed and undoable before partial feedback',
    insertSource.includes('this.undoRedo.push(action, prepared);') &&
    insertSource.includes('this.refreshImageAssets(generation, pageId);') &&
    insertSource.includes('return { insertedCount: results.length, totalCount: plans.length };')],
  ['partial failure is localized in both resource tables',
    hasValue(base, 'original_photo_insert_partial_failed', "Some photos couldn't be added") &&
    hasValue(zh, 'original_photo_insert_partial_failed', '部分图片未能添加')],
  ['ArkTS fixture proves the non-empty strict prefix contract',
    fixture.includes('insertedCount < outcome.totalCount') &&
    fixtureList.includes('originalPhotoHistoryMetadataTest();')],
];

let failed = 0;
for (const [name, passed] of checks) {
  console.log(`${passed ? 'PASS' : 'FAIL'} ${name}`);
  if (!passed) failed++;
}
console.log(`D02_ORIGINAL_PHOTO_PARTIAL_FAILURE_OK TOTAL=${checks.length} FAILED=${failed}`);
if (failed > 0) process.exitCode = 1;
