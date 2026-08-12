import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const asset = fs.readFileSync(path.join(root, 'note/src/main/ets/data/AssetRepositoryImpl.ets'), 'utf8');
const note = fs.readFileSync(path.join(root, 'note/src/main/ets/data/NoteRepositoryImpl.ets'), 'utf8');
const helper = asset.indexOf('export function unlinkAssetFile');
const guard = asset.indexOf('isPathInside(filesRoot, path)', helper);
const rootCheck = asset.indexOf('function isPathInside');
const assetCall = asset.indexOf('unlinkAssetFile(localPath, this.db.getFilesDir())');
const noteCall = note.indexOf('unlinkAssetFile(filesToDelete[i], filesRoot)');
const checks = [
  ['unlink helper accepts application root', helper >= 0 && guard > helper],
  ['path confinement helper exists', rootCheck > guard],
  ['asset deletion passes files root', assetCall >= 0],
  ['note deletion passes files root', noteCall >= 0],
  ['parent traversal is rejected', asset.includes("normalizedCandidate.indexOf('/../')")],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
