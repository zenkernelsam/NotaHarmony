import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const schema = read('note/src/main/ets/data/DatabaseHelper.ets');
const consumer = read('note/src/main/ets/data/OriginalRecordingStore.ets');
const tests = read('note/src/test/OriginalRecordingStore.test.ets');
const list = read('note/src/test/List.test.ets');

const recordingDdl = extractTemplate(schema, 'DDL_ORIGINAL_RECORDING_STATE');
const visibilityDdl = extractTemplate(schema, 'DDL_ORIGINAL_ENTITY_VISIBILITY_WINNER');
const db = new DatabaseSync(':memory:');
db.exec(`PRAGMA foreign_keys=ON;
  CREATE TABLE note_meta(id TEXT PRIMARY KEY);
  CREATE TABLE note_asset(asset_hash TEXT PRIMARY KEY, status INTEGER NOT NULL,
    note_ids TEXT NOT NULL, file_size INTEGER NOT NULL, mime_type TEXT NOT NULL, local_path TEXT);
  ${visibilityDdl};
  ${recordingDdl};
  INSERT INTO note_meta VALUES('n');`);

function insertRecording(timestamp, site, zIndex, suffix) {
  const segments = JSON.stringify([{ startTime: '100', endTime: '200' }]);
  db.prepare(`INSERT INTO original_recording_state VALUES(
    'n',?,?, ?,?,?,?, '100','200', ?,?,0,0,0, ?,?,0,0,0, ?,?,0,0,0, ?)`)
    .run(timestamp, site, JSON.stringify(['1','2','3','4','5','6','7','8']),
      `audio-${suffix}.m4a`, 'audio/mp4', 4096, `Recording ${suffix}`, `Recording ${suffix}`,
      segments, segments, zIndex, zIndex, `signature-${suffix}`);
}

insertRecording(20, 2, '18446744073709551615', 'high');
insertRecording(21, 1, '9', 'deleted');
insertRecording(22, 3, '10', 'ready');
db.prepare(`INSERT INTO original_entity_visibility_winner VALUES('n',21,1,30,1,1)`).run();

const visible = db.prepare(`SELECT recording_timestamp, recording_site_id, name_value,
    segments_value, z_index_value FROM original_recording_state recording
  LEFT JOIN original_entity_visibility_winner visibility ON visibility.note_id=recording.note_id
    AND visibility.entity_timestamp=recording.recording_timestamp
    AND visibility.entity_site_id=recording.recording_site_id
  WHERE recording.note_id=? AND COALESCE(visibility.deleted,0)=0`).all('n');
assert.deepEqual(visible.map(row => row.recording_timestamp), [20, 22]);
visible.sort((left, right) => left.z_index_value.length - right.z_index_value.length ||
  left.z_index_value.localeCompare(right.z_index_value) ||
  left.recording_timestamp - right.recording_timestamp ||
  left.recording_site_id - right.recording_site_id);
assert.deepEqual(visible.map(row => row.recording_timestamp), [22, 20]);
assert.deepEqual(JSON.parse(visible[0].segments_value), [{ startTime: '100', endTime: '200' }]);

assert.match(consumer, /class OriginalRecordingStore/);
assert.match(consumer, /COALESCE\(visibility\.deleted, 0\) = 0/);
assert.match(consumer, /recordings\.sort\(compareMaterializedRecordings\)/);
assert.match(consumer, /compareUnsignedLongDecimal\(left\.zIndex, right\.zIndex\)/);
assert.match(consumer, /OriginalRecordingAssetState\.MISSING/);
assert.match(consumer, /OriginalRecordingAssetState\.PENDING/);
assert.match(consumer, /OriginalRecordingAssetState\.READY/);
assert.match(consumer, /OriginalRecordingAssetState\.FAILED/);
assert.match(consumer, /asset\.fileSize !== assetFileSize/);
assert.match(consumer, /originalAssetStorageHash\(assetHashBits\)/);
assert.match(consumer, /originalAssetHashKey\(assetHashBits\)/);
assert.match(tests, /AssetStatus\.DOWNLOADED/);
assert.match(tests, /9007199254740993/);
assert.match(tests, /18446744073709551615/);
assert.match(list, /originalRecordingStoreTest\(\)/);

db.close();
console.log('recordingConsumer=visible-lww-zorder-asset-state');

function extractTemplate(source, name) {
  const match = source.match(new RegExp('(?:export )?const ' + name +
    ': string = `([\\s\\S]*?)`;'));
  assert(match, `${name} missing`);
  return match[1];
}
