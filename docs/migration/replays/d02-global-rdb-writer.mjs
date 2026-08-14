import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const dataRoot = path.join(root, 'note/src/main/ets/data');

function read(relative) {
  return fs.readFileSync(path.join(root, relative), 'utf8');
}

function section(source, startText, endText) {
  const start = source.indexOf(startText);
  const end = source.indexOf(endText, start + startText.length);
  if (start < 0 || end < 0) return '';
  return source.slice(start, end);
}

function etsFiles(directory) {
  const files = [];
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const absolute = path.join(directory, entry.name);
    if (entry.isDirectory()) files.push(...etsFiles(absolute));
    else if (entry.isFile() && entry.name.endsWith('.ets')) files.push(absolute);
  }
  return files;
}

const writer = read('note/src/main/ets/data/DatabaseWriteMutex.ets');
const editorAlias = read('note/src/main/ets/data/EditorPersistenceMutex.ets');
const libraryAlias = read('note/src/main/ets/data/LibraryMetadataMutationMutex.ets');
const asset = read('note/src/main/ets/data/AssetRepositoryImpl.ets');
const imageAsset = read('note/src/main/ets/data/ImageAssetPackageStore.ets');
const recording = read('note/src/main/ets/data/OriginalRecordingPersistence.ets');
const tool = read('note/src/main/ets/data/ToolRepositoryImpl.ets');
const note = read('note/src/main/ets/data/NoteRepositoryImpl.ets');
const database = read('note/src/main/ets/data/DatabaseManager.ets');

const saveAsset = section(asset, 'async saveAsset(', 'async getAssetsByNote(');
const deleteAsset = section(asset, 'async deleteAsset(', 'private rowToAsset(');
const writeImage = section(imageAsset, 'async function writeOriginalImageAssetBytes(',
  'function validateArrivalMetadata(');
const persistRecording = section(recording, 'export async function persistCapturedOriginalRecording(',
  'async function prepareRecordingAsset(');
const saveViewState = section(note, 'async saveViewState(', 'private rowToNote(');

const runtimeTransactionFiles = etsFiles(dataRoot).filter((file) =>
  !file.endsWith(`${path.sep}DatabaseManager.ets`) &&
  fs.readFileSync(file, 'utf8').includes('beginTransaction('));
const uncoveredTransactionFiles = runtimeTransactionFiles.filter((file) => {
  const source = fs.readFileSync(file, 'utf8');
  return !source.includes('databaseWriteMutex') &&
    !source.includes('editorPersistenceMutex') &&
    !source.includes('libraryMetadataMutationMutex');
});

const checks = [
  ['one module owns the published RdbStore writer', writer.includes(
    'export const databaseWriteMutex: AsyncMutex = new AsyncMutex()')],
  ['editor persistence is a compatibility alias', editorAlias.includes(
    'export const editorPersistenceMutex: AsyncMutex = databaseWriteMutex') &&
    !editorAlias.includes('new AsyncMutex()')],
  ['library metadata is a compatibility alias', libraryAlias.includes(
    'export const libraryMetadataMutationMutex: AsyncMutex = databaseWriteMutex') &&
    !libraryAlias.includes('new AsyncMutex()')],
  ['every runtime transaction file reaches the shared writer',
    runtimeTransactionFiles.length > 0 && uncoveredTransactionFiles.length === 0],
  ['asset repository keeps asset-before-database lock order',
    saveAsset.indexOf('assetMutationMutex.runExclusive') <
      saveAsset.indexOf('databaseWriteMutex.runExclusive') &&
    deleteAsset.indexOf('assetMutationMutex.runExclusive') <
      deleteAsset.indexOf('databaseWriteMutex.runExclusive')],
  ['asset canonical file detaches after commit but before writer release',
    deleteAsset.indexOf('await store.commit()') <
      deleteAsset.indexOf('detachAssetFileForDeletion(committedLocalPath, filesRoot)') &&
    deleteAsset.indexOf('detachAssetFileForDeletion(committedLocalPath, filesRoot)') <
      deleteAsset.indexOf('        });',
        deleteAsset.indexOf('detachAssetFileForDeletion(committedLocalPath, filesRoot)'))],
  ['asset quarantine unlink is outside the database writer',
    deleteAsset.indexOf('        });',
      deleteAsset.indexOf('detachAssetFileForDeletion(committedLocalPath, filesRoot)')) <
      deleteAsset.indexOf('unlinkAssetFile(detachedPath, filesRoot)')],
  ['image arrival keeps asset-before-database lock order',
    writeImage.indexOf('assetMutationMutex.runExclusive') <
      writeImage.indexOf('databaseWriteMutex.runExclusive') &&
    writeImage.indexOf('databaseWriteMutex.runExclusive') < writeImage.indexOf('beginTransaction(')],
  ['recording capture keeps asset-before-database lock order',
    persistRecording.indexOf('assetMutationMutex.runExclusive') <
      persistRecording.indexOf('editorPersistenceMutex.runExclusive') &&
    persistRecording.indexOf('editorPersistenceMutex.runExclusive') <
      persistRecording.indexOf('beginTransaction(')],
  ['tool writes no longer own a private database writer',
    !tool.includes('private static writeMutex') &&
    (tool.match(/databaseWriteMutex\.runExclusive/g) ?? []).length === 4],
  ['view-state replacement shares the database writer',
    saveViewState.includes('databaseWriteMutex.runExclusive')],
  ['initialization transactions finish before the store is published',
    database.lastIndexOf('beginTransaction(') < database.indexOf('this.rdbStore = store')],
];

for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`RUNTIME_TRANSACTION_FILES=${runtimeTransactionFiles.length}`);
console.log(`TOTAL=${checks.length} FAILED=0`);
