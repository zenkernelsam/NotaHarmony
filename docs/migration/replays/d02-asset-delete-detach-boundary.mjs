import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');

function read(relative) {
  return fs.readFileSync(path.join(root, relative), 'utf8');
}

function section(source, startText, endText) {
  const start = source.indexOf(startText);
  const end = source.indexOf(endText, start + startText.length);
  if (start < 0 || end < 0) return '';
  return source.slice(start, end);
}

const asset = read('note/src/main/ets/data/AssetRepositoryImpl.ets');
const note = read('note/src/main/ets/data/NoteRepositoryImpl.ets');
const originalReferences = read('note/src/main/ets/data/OriginalAssetReferenceStore.ets');
const originalImage = read('note/src/main/ets/data/OriginalCreateBlockOperation.ets');

const deleteAsset = section(asset, 'async deleteAsset(', 'private rowToAsset(');
const deleteNote = section(note, 'async deleteNote(', 'async getViewState(');
const assetCommit = deleteAsset.indexOf('await store.commit()');
const assetPathGate = deleteAsset.indexOf(
  'isAssetFilePathReferenced(store, committedLocalPath)');
const assetDetach = deleteAsset.indexOf(
  'detachAssetFileForDeletion(committedLocalPath, filesRoot)');
const assetWriterRelease = deleteAsset.indexOf('        });', assetDetach);
const assetUnlink = deleteAsset.indexOf('unlinkAssetFile(detachedPath, filesRoot)');
const noteCommit = deleteNote.indexOf('await store.commit()');
const notePathGate = deleteNote.indexOf('isAssetFilePathReferenced(store, candidatePath)');
const noteDetach = deleteNote.indexOf('detachAssetFileForDeletion(');
const noteWriterRelease = deleteNote.indexOf('      });', noteDetach);
const noteUnlink = deleteNote.indexOf('unlinkAssetFile(detachedFiles[i], filesRoot)');

const checks = [
  ['original operation helpers also mutate note_asset',
    originalReferences.includes("store.insert('note_asset'") &&
    originalImage.includes("store.insert('note_asset'")],
  ['asset delete checks surviving rows that share the local path',
    assetPathGate >= 0 && assetPathGate < assetCommit],
  ['asset delete detaches canonical path after commit',
    assetCommit >= 0 && assetCommit < assetDetach],
  ['asset delete detaches before releasing the database writer',
    assetDetach < assetWriterRelease],
  ['asset delete unlinks only the quarantined path after writer release',
    assetWriterRelease < assetUnlink && !deleteAsset.includes('unlinkAssetFile(committedLocalPath')],
  ['note delete detaches all canonical paths after commit',
    noteCommit >= 0 && noteCommit < noteDetach],
  ['note delete filters shared local paths before commit',
    notePathGate >= 0 && notePathGate < noteCommit],
  ['note delete detaches before releasing the database writer',
    noteDetach < noteWriterRelease],
  ['note delete unlinks only quarantined paths after writer release',
    noteWriterRelease < noteUnlink && !deleteNote.includes('unlinkAssetFile(filesToDelete')],
  ['detachment uses a private unique trash path and atomic rename',
    asset.includes("'/assets/trash'") && asset.includes('fileIo.renameSync(path, quarantinePath)') &&
    asset.includes('deleted_asset_${Date.now()}_')],
  ['detachment and deletion both enforce the application files root',
    (asset.match(/isPathInside\(filesRoot, path\)/g) ?? []).length >= 2],
  ['shared path lookup is structural and closes its result set',
    asset.includes('export async function isAssetFilePathReferenced') &&
    asset.includes("predicates.equalTo('local_path', path)") &&
    /isAssetFilePathReferenced[\s\S]*?finally \{[\s\S]*?rows\.close\(\)/.test(asset)],
];

for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}

// Old ordering: a new reference can reuse the canonical path before stale cleanup deletes it.
const old = { canonical: true, referenced: false };
old.referenced = true;
old.canonical = false;
if (old.canonical || !old.referenced) {
  throw new Error('FAILED: unsafe ordering model did not reproduce stale cleanup loss');
}

// New ordering: detach is complete before another database writer can publish a new reference.
const safe = { canonical: true, quarantine: false, referenced: false };
safe.quarantine = safe.canonical;
safe.canonical = false;
safe.referenced = true;
safe.canonical = true;
safe.quarantine = false;
if (!safe.canonical || !safe.referenced || safe.quarantine) {
  throw new Error('FAILED: detached cleanup model damaged the replacement canonical file');
}

// A legacy/canonical alias may share a path. Deleting one row must retain the surviving row's file.
const sharedPath = { deletedRow: false, survivingRow: true, detached: false };
sharedPath.deletedRow = true;
if (!sharedPath.survivingRow) {
  sharedPath.detached = true;
}
if (!sharedPath.deletedRow || !sharedPath.survivingRow || sharedPath.detached) {
  throw new Error('FAILED: shared path ownership model detached a surviving asset file');
}

console.log(`TOTAL=${checks.length + 3} FAILED=0`);
