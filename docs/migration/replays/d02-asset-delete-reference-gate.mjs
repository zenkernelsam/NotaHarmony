import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/AssetRepositoryImpl.ets'), 'utf8');
const method = source.indexOf('async deleteAsset(hash: string)');
const query = source.indexOf("store.query(queryPredicates, ['local_path', 'note_ids'])", method);
const parse = source.indexOf('parseAssetNoteIds', query);
const gate = source.indexOf('asset is still referenced', parse);
const remove = source.indexOf('await store.delete(predicates)', gate);
const pathGate = source.indexOf('isAssetFilePathReferenced(store, committedLocalPath)', remove);
const commit = source.indexOf('await store.commit()', pathGate);
const detach = source.indexOf('detachAssetFileForDeletion(committedLocalPath, filesRoot)', commit);
const writerRelease = source.indexOf('        });', detach);
const unlink = source.indexOf('unlinkAssetFile(detachedPath, filesRoot)', writerRelease);
const exclusiveEnd = source.indexOf('    });', unlink);
const checks = [
  ['delete reads reference set', query > method && parse > query],
  ['referenced assets are rejected', gate > parse],
  ['database delete follows gate', remove > gate],
  ['shared local paths remain owned by surviving asset rows', pathGate > remove && commit > pathGate],
  ['transaction commits before canonical file detachment', commit > remove && detach > commit],
  ['canonical file detaches before the database writer is released', writerRelease > detach],
  ['quarantined file unlink occurs after the database writer is released', unlink > writerRelease],
  ['file unlink remains inside the asset mutation mutex', exclusiveEnd > unlink],
  ['failure rolls back transaction', source.indexOf('await store.rollBack()', gate) > gate],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
