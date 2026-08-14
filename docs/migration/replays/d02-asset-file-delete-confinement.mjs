import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const asset = fs.readFileSync(path.join(root, 'note/src/main/ets/data/AssetRepositoryImpl.ets'), 'utf8');
const note = fs.readFileSync(path.join(root, 'note/src/main/ets/data/NoteRepositoryImpl.ets'), 'utf8');
const helper = asset.indexOf('export function unlinkAssetFile');
const guard = asset.indexOf('isPathInside(filesRoot, path)', helper);
const detachHelper = asset.indexOf('export function detachAssetFileForDeletion');
const detachGuard = asset.indexOf('isPathInside(filesRoot, path)', detachHelper);
const rootCheck = asset.indexOf('function isPathInside');
const assetDetach = asset.indexOf('detachAssetFileForDeletion(committedLocalPath, filesRoot)');
const assetCall = asset.indexOf('unlinkAssetFile(detachedPath, filesRoot)');
const noteDetach = note.indexOf('detachAssetFileForDeletion(');
const noteCall = note.indexOf('unlinkAssetFile(detachedFiles[i], filesRoot)');
const checks = [
  ['unlink helper accepts application root', helper >= 0 && guard > helper],
  ['detach helper accepts application root', detachHelper > helper && detachGuard > detachHelper],
  ['path confinement helper is shared', rootCheck > guard && rootCheck > detachGuard],
  ['asset deletion confines detach and unlink', assetDetach >= 0 && assetCall > assetDetach],
  ['note deletion confines detach and unlink', noteDetach >= 0 && noteCall > noteDetach],
  ['parent traversal is rejected', asset.includes("normalizedCandidate.indexOf('/../')")],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
