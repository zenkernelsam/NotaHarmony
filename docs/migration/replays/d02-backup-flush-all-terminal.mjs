import assert from 'node:assert/strict';
import fs from 'node:fs';

const persistence = fs.readFileSync('note/src/main/ets/data/StrokePersistence.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const exporter = fs.readFileSync('note/src/main/ets/data/NoteExporter.ets', 'utf8')
  .replaceAll('\r\n', '\n');

function functionBody(source, startMarker, endMarker) {
  const start = source.indexOf(startMarker);
  const end = source.indexOf(endMarker, start);
  assert.ok(start !== -1 && end > start, startMarker);
  return source.slice(start, end);
}

const flushAll = functionBody(persistence, 'async flushAll(): Promise<void> {', '\n  hasPendingSaves()');
const exportAll = functionBody(exporter, 'async exportAllNotes()', '\n  private addAsset');
assert.ok(!flushAll.includes('while (true)'), 'flushAll must not retry failed queues forever');
assert.match(flushAll, /const dirtyQueues: LatestWriteQueue<PreparedPageSave>\[\] = \[\];/);
assert.match(flushAll, /for \(const queue of dirtyQueues\) \{\s+await queue\.flush\(\);/);
assert.match(flushAll, /if \(!queue\.isDirty\(\)\) \{\s+StrokePersistence\.saveQueueRegistry\.delete\(queue\);\s+\}/);
assert.match(exportAll, /await this\.persistence\.flushAll\(\);/);
assert.match(exportAll, /if \(this\.persistence\.hasPendingSaves\(\)\) \{[\s\S]{0,160}BackupSnapshotChangedError/);

console.log('D02_BACKUP_FLUSH_ALL_TERMINAL_REPLAY_OK TOTAL=6 FAILED=0');
