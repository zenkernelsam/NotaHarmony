import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8').replaceAll('\r\n', '\n');
const history = fs.readFileSync('note/src/main/ets/data/PersistentHistory.ets', 'utf8').replaceAll('\r\n', '\n');
const persistence = fs.readFileSync('note/src/main/ets/data/StrokePersistence.ets', 'utf8').replaceAll('\r\n', '\n');
const fixture = fs.readFileSync('note/src/test/OriginalPhotoHistoryMetadata.test.ets', 'utf8');
const fixtureList = fs.readFileSync('note/src/test/List.test.ets', 'utf8');

const commitStart = canvas.indexOf('private async commitOriginalPhotoInsert');
const commitEnd = canvas.indexOf('private async confirmMathInsert', commitStart);
const commitSource = canvas.slice(commitStart, commitEnd);
const checks = [
  ['multi-image runtime action derives one final order',
    commitSource.includes('const finalOrder: PageElementRef[] =') &&
    commitSource.includes('results[results.length - 1].elementOrder')],
  ['runtime ADD_ELEMENTS carries every inserted image ref',
    commitSource.includes('const addedElementOrder: PageElementRef[] = finalImages.map(') &&
    commitSource.includes('kind: PageElementKind.IMAGE') &&
    commitSource.includes('elementId: image.id')],
  ['added refs continue the captured before-order clock',
    commitSource.includes('zIndex: elementOrderBefore.length + index') &&
    commitSource.includes('addedElementOrder: addedElementOrder')],
  ['durable companion operations group by one prepared actionId',
    persistence.includes('const stableHistory: HistoryMetadata = {') &&
    persistence.includes('actionId: history.actionId, effect: history.effect,') &&
    persistence.includes('await this.appendHistoryCompanion(store, finalSnapshot, mutation);')],
  ['persistent reducer groups adjacent identical PUSH metadata',
    history.includes('sameEvent(active.metadata, operation.history)') &&
    history.includes('operations: event.operations.slice()')],
  ['persistent element actions validate contiguous revisions',
    history.includes('mutation.fromRevision !== previousRevision') &&
    history.includes("'persistent element action revisions are not contiguous'")],
  ['ArkTS fixture proves ordered image history refs and suite registration',
    fixture.includes('PageElementKind.IMAGE') &&
    fixture.includes('zIndex: beforeCount + index') &&
    fixtureList.includes("import originalPhotoHistoryMetadataTest from './OriginalPhotoHistoryMetadata.test';") &&
    fixtureList.includes('originalPhotoHistoryMetadataTest();')],
];
let failed = 0;
for (const [name, passed] of checks) {
  console.log(`${passed ? 'PASS' : 'FAIL'} ${name}`);
  if (!passed) failed++;
}
console.log(`D02_ORIGINAL_PHOTO_HISTORY_METADATA_OK TOTAL=${checks.length} FAILED=${failed}`);
if (failed > 0) process.exitCode = 1;
