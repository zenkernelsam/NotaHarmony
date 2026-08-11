import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const read = value => fs.readFileSync(new URL('../../../' + value, import.meta.url), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const originalS5j = fs.readFileSync(originalRoot + 's5j.java', 'utf8');
const originalU5j = fs.readFileSync(originalRoot + 'u5j.java', 'utf8');
const originalKci = fs.readFileSync(originalRoot + 'kci.java', 'utf8');
const originalTej = fs.readFileSync(originalRoot + 'tej.java', 'utf8');
const originalVej = fs.readFileSync(originalRoot + 'vej.java', 'utf8');
const encoder = read('note/src/main/ets/data/OriginalInsertTextPayloadEncoder.ets');
const planner = read('note/src/main/ets/data/OriginalLocalTextMutation.ets');
const reducer = read('note/src/main/ets/data/OriginalInsertTextOperation.ets');
const blockEncoder = read('note/src/main/ets/data/OriginalModifyBlockPayloadEncoder.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const history = read('note/src/main/ets/data/PersistentHistory.ets');
const opTypes = read('note/src/main/ets/core/model/OpTypes.ets');
const fixtures = read('note/src/test/OriginalTextMutationPayloadEncoder.test.ets');

assert.match(originalS5j, /Character\.codePointCount\(str, 0, str\.length\(\)\) != 1/);
assert.match(originalS5j, /return kci\.b\(excVar, str, qo5Var\)/);
assert.match(originalS5j, /aVarA\.e\(1, iCodePointAt, 0\)/);
assert.match(originalKci, /aVarA\.C\(3\)/);
assert.match(originalKci, /aVarA\.h\(1, iC\)/);
assert.match(originalU5j, /iD2 != 1 \? vej\.a\(th7VarE, qo5Var\) : tej\.a/);
assert.match(originalU5j, /public static final f2c G\(qo5 qo5Var, x09 x09Var, List list\)/);
assert.match(originalTej, /aVarA\.C\(2\)/);
assert.match(originalTej, /aVarA\.j\(0, sg5\.f\(aVarA, excVar\)\)/);
assert.match(originalVej, /aVarA\.D\(12, size, 4\)/);
assert.match(originalVej, /aVarA\.h\(0, numValueOf\.intValue\(\)\)/);

assert.match(encoder, /encodeOriginalTextInsertion/);
assert.match(encoder, /scalars\.length === 1/);
assert.match(encoder, /ORIGINAL_INSERT_CHAR_PAYLOAD_TYPE/);
assert.match(encoder, /ORIGINAL_INSERT_STRING_PAYLOAD_TYPE/);
assert.match(encoder, /encodeOriginalTextVisibility/);
assert.match(encoder, /ORIGINAL_REMOVE_CHAR_PAYLOAD_TYPE/);
assert.match(encoder, /ORIGINAL_REMOVE_CHARS_PAYLOAD_TYPE/);
assert.match(encoder, /ORIGINAL_REVIVE_CHARS_PAYLOAD_TYPE/);
assert.match(planner, /materializeOriginalTextCharacterOrder/);
assert.match(planner, /findReviveCandidate/);
assert.match(planner, /insertedScalars: revived\.length === 0 \? insertedScalars : \[\]/);
assert.match(reducer, /OriginalTextVisibilityOperationApplier/);
assert.match(reducer, /applyBatchedPayload/);
assert.match(blockEncoder, /encodeOriginalBlockSize/);
assert.match(blockEncoder, /fields\[6\] = 8/);
assert.match(persistence, /originalTextMutation/);
assert.match(persistence, /applyOriginalTextMutation/);
assert.match(persistence, /new OriginalPageMutationBatch\(\)/);
assert.match(persistence, /await revisionBatch\.flush\(store, step\.noteId\)/);
assert.match(persistence, /uploadImmediately: true/);
assert.match(persistence, /local Text reducers produced unexpected final state/);
assert.match(history, /OpType\.ORIGINAL_TEXT_VISIBILITY/);
assert.match(opTypes, /ORIGINAL_TEXT_VISIBILITY = 73/);
assert.match(fixtures, /identity-preserving undo-redo by Unicode scalar/);

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE page(id INTEGER PRIMARY KEY, revision INTEGER NOT NULL);
  CREATE TABLE block(id TEXT PRIMARY KEY, text TEXT NOT NULL, width REAL NOT NULL,
    height REAL NOT NULL);
  CREATE TABLE character(id TEXT PRIMARY KEY, parent_id TEXT, scalar INTEGER NOT NULL,
    visible INTEGER NOT NULL, winner INTEGER);
  CREATE TABLE operation(seq INTEGER PRIMARY KEY AUTOINCREMENT, identity INTEGER NOT NULL,
    payload_type INTEGER NOT NULL, target TEXT NOT NULL, upload INTEGER NOT NULL);
  INSERT INTO page VALUES(1,0);
  INSERT INTO block VALUES('op:50:7','ABC',200,40);
  INSERT INTO character VALUES('10:7:0',NULL,65,1,NULL);
  INSERT INTO character VALUES('10:7:1','10:7:0',66,1,NULL);
  INSERT INTO character VALUES('10:7:2','10:7:1',67,1,NULL);`);

function identityParts(id) {
  const [timestamp, site, index] = id.split(':').map(Number);
  return { timestamp, site, index };
}

function materialize() {
  const rows = db.prepare('SELECT id,parent_id,scalar,visible FROM character').all();
  const children = new Map();
  for (const row of rows) {
    const key = row.parent_id ?? 'ROOT';
    const values = children.get(key) ?? [];
    values.push(row);
    children.set(key, values);
  }
  for (const values of children.values()) {
    values.sort((left, right) => {
      const a = identityParts(left.id);
      const b = identityParts(right.id);
      return b.timestamp - a.timestamp || b.site - a.site || b.index - a.index;
    });
  }
  const result = [];
  const stack = [...(children.get('ROOT') ?? [])].reverse();
  while (stack.length > 0) {
    const row = stack.pop();
    if (row.visible) result.push(String.fromCodePoint(row.scalar));
    const descendants = children.get(row.id) ?? [];
    for (let index = descendants.length - 1; index >= 0; index--) stack.push(descendants[index]);
  }
  return result.join('');
}

function edit({ before, after, operations, size = null, failAfter = null }) {
  db.exec('BEGIN IMMEDIATE');
  try {
    assert.equal(db.prepare('SELECT text FROM block').get().text, before);
    const baseRevision = db.prepare('SELECT revision FROM page').get().revision;
    for (let index = 0; index < operations.length; index++) {
      const operation = operations[index];
      if (operation.kind === 'remove' || operation.kind === 'revive') {
        const visible = operation.kind === 'revive' ? 1 : 0;
        const changed = db.prepare(
          'UPDATE character SET visible=?,winner=? WHERE id=?').run(
          visible, operation.identity, operation.target);
        assert.equal(changed.changes, 1);
      } else {
        db.prepare('INSERT INTO character VALUES(?,?,?,?,NULL)').run(
          operation.target, operation.parent, operation.scalar, 1);
      }
      db.prepare('INSERT INTO operation(identity,payload_type,target,upload) VALUES(?,?,?,1)').run(
        operation.identity, operation.type, operation.target);
      if (failAfter === index) throw new Error('injected text transaction failure');
    }
    if (size !== null) {
      db.prepare('UPDATE block SET width=?,height=?').run(size.width, size.height);
      db.prepare('INSERT INTO operation(identity,payload_type,target,upload) VALUES(19,19,?,1)')
        .run('op:50:7');
    }
    const actual = materialize();
    assert.equal(actual, after);
    db.prepare('UPDATE block SET text=?').run(actual);
    db.prepare('UPDATE page SET revision=?').run(baseRevision + 1);
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

edit({ before: 'ABC', after: 'AXC', size: { width: 200, height: 48 }, operations: [
  { kind: 'remove', identity: 20, type: 9, target: '10:7:1' },
  { kind: 'insert', identity: 21, type: 7, target: '21:7:0', parent: '10:7:0', scalar: 88 },
] });
assert.equal(db.prepare('SELECT revision FROM page').get().revision, 1);
assert.deepEqual(db.prepare('SELECT payload_type,upload FROM operation ORDER BY seq').all()
  .map(row => ({ payload_type: row.payload_type, upload: row.upload })), [
  { payload_type: 9, upload: 1 }, { payload_type: 7, upload: 1 },
  { payload_type: 19, upload: 1 },
]);
const resized = db.prepare('SELECT width,height FROM block').get();
assert.deepEqual({ width: resized.width, height: resized.height }, { width: 200, height: 48 });

edit({ before: 'AXC', after: 'ABC', operations: [
  { kind: 'remove', identity: 22, type: 9, target: '21:7:0' },
  { kind: 'revive', identity: 23, type: 11, target: '10:7:1' },
] });
edit({ before: 'ABC', after: 'AXC', operations: [
  { kind: 'remove', identity: 24, type: 9, target: '10:7:1' },
  { kind: 'revive', identity: 25, type: 11, target: '21:7:0' },
] });
assert.equal(db.prepare('SELECT revision FROM page').get().revision, 3);
assert.equal(db.prepare("SELECT COUNT(*) AS count FROM character WHERE scalar=88").get().count, 1);
assert.equal(db.prepare("SELECT visible FROM character WHERE id='21:7:0'").get().visible, 1);

edit({ before: 'AXC', after: 'A\u{1F600}XC', operations: [
  { kind: 'insert', identity: 26, type: 7, target: '26:7:0', parent: '10:7:0', scalar: 0x1F600 },
] });
assert.equal(db.prepare('SELECT text FROM block').get().text, 'A\u{1F600}XC');
assert.equal(db.prepare('SELECT revision FROM page').get().revision, 4);

const beforeFailure = {
  revision: db.prepare('SELECT revision FROM page').get().revision,
  text: db.prepare('SELECT text FROM block').get().text,
  operations: db.prepare('SELECT COUNT(*) AS count FROM operation').get().count,
};
assert.throws(() => edit({ before: 'A\u{1F600}XC', after: 'AC', failAfter: 0, operations: [
  { kind: 'remove', identity: 27, type: 10, target: '26:7:0' },
  { kind: 'remove', identity: 27, type: 10, target: '21:7:0' },
] }), /injected text transaction failure/);
assert.deepEqual({
  revision: db.prepare('SELECT revision FROM page').get().revision,
  text: db.prepare('SELECT text FROM block').get().text,
  operations: db.prepare('SELECT COUNT(*) AS count FROM operation').get().count,
}, beforeFailure);
assert.equal(materialize(), beforeFailure.text);
db.close();

console.log('localTextEdit=original-type7-8-9-10-11-unicode-size-single-revision-' +
  'persistent-undo-redo-revive-identity-rollback');
