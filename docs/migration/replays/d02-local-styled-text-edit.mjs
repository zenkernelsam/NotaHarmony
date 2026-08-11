import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const read = value => fs.readFileSync(new URL('../../../' + value, import.meta.url), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const originalM4c = fs.readFileSync(originalRoot + 'm4c.java', 'utf8');
const planner = read('note/src/main/ets/data/OriginalLocalTextMutation.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const textTool = read('note/src/main/ets/rendering/TextBlockTool.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const fixtures = read('note/src/test/OriginalTextMutationPayloadEncoder.test.ets');

assert.match(originalM4c, /y01 y01Var = y01\.BEFORE/);
assert.match(originalM4c, /y01Var = y01\.END_OF_DOC/);
assert.match(originalM4c, /rz1\.a\(excVar4, y01\.AFTER\)/);
assert.match(planner, /previewOriginalLocalTextMutation/);
assert.match(planner, /predictOriginalTextInsertionIdentity/);
assert.match(planner, /nextOperationTimestamp\(timestamp\)/);
assert.match(planner, /materializeOriginalTextStyles/);
assert.match(persistence, /previewOriginalTextEdit/);
assert.match(persistence, /readOriginalTextStyleOperations/);
assert.match(persistence, /readOriginalCheckboxStates/);
assert.match(persistence, /sameTextStyleRuns\(after/);
assert.match(canvas, /await this\.persistence\.previewOriginalTextEdit/);
assert.match(canvas, /preview\.characterStyleRuns, preview\.paragraphStyleRuns/);
assert.match(canvas, /original Text edit rejected because CRDT style preview diverged/);
assert.match(canvas, /if \(!await this\.onTextCommit\(this\.editingDraftText\)\) \{/);
assert.match(canvas, /this\.disposeRenderingResources\(\)/);
assert.match(textTool, /if \(characterStyleRuns !== undefined && paragraphStyleRuns !== undefined\)/);
assert.match(textTool, /updated\.characterStyleRuns = cloneCharacterStyleRuns\(characterStyleRuns\)/);
assert.match(fixtures, /keeps paragraph checkbox state attached to its SeqId/);
assert.match(fixtures, /rejects clock exhaustion/);

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE page(id INTEGER PRIMARY KEY, revision INTEGER NOT NULL);
  CREATE TABLE block(id TEXT PRIMARY KEY, text TEXT NOT NULL, character_runs TEXT NOT NULL,
    paragraph_runs TEXT NOT NULL);
  CREATE TABLE character(id TEXT PRIMARY KEY, parent_id TEXT, scalar INTEGER NOT NULL,
    visible INTEGER NOT NULL);
  CREATE TABLE style(identity INTEGER PRIMARY KEY, paragraph INTEGER NOT NULL,
    start_id TEXT, start_type INTEGER NOT NULL, end_id TEXT, end_type INTEGER NOT NULL,
    attributes TEXT NOT NULL);
  CREATE TABLE checkbox(location_id TEXT PRIMARY KEY, checked INTEGER NOT NULL);
  CREATE TABLE operation(identity INTEGER PRIMARY KEY, kind TEXT NOT NULL, upload INTEGER NOT NULL);
  INSERT INTO page VALUES(1,0);
  INSERT INTO block VALUES('op:50:7','ABC','[{"start":1,"end":3,"style":{"bold":true}}]',
    '[{"start":1,"end":2,"style":{"decoratorStyle":3,"isChecked":true}}]');
  INSERT INTO character VALUES('10:7:0',NULL,65,1);
  INSERT INTO character VALUES('10:7:1','10:7:0',66,1);
  INSERT INTO character VALUES('10:7:2','10:7:1',67,1);
  INSERT INTO style VALUES(5,0,'10:7:1',0,'10:7:2',1,'{"bold":true}');
  INSERT INTO style VALUES(6,1,'10:7:1',0,'10:7:1',1,'{"decoratorStyle":3}');
  INSERT INTO checkbox VALUES('10:7:1',1);`);

function parts(id) {
  const [timestamp, site, index] = id.split(':').map(Number);
  return { timestamp, site, index };
}

function compareSequence(leftId, rightId) {
  const left = parts(leftId), right = parts(rightId);
  const timestamp = ((left.timestamp | 0) - (right.timestamp | 0)) | 0;
  if (timestamp !== 0) return timestamp < 0 ? -1 : 1;
  if (left.site !== right.site) return left.site < right.site ? -1 : 1;
  return right.index - left.index;
}

function orderedCharacters() {
  const rows = db.prepare('SELECT id,parent_id,scalar,visible FROM character').all();
  const children = new Map();
  for (const row of rows) {
    const key = row.parent_id ?? 'ROOT';
    const list = children.get(key) ?? [];
    list.push(row); children.set(key, list);
  }
  for (const list of children.values()) {
    list.sort((left, right) => -compareSequence(left.id, right.id));
  }
  const ordered = [], stack = [...(children.get('ROOT') ?? [])].reverse();
  while (stack.length > 0) {
    const row = stack.pop(); ordered.push(row);
    const descendants = children.get(row.id) ?? [];
    for (let index = descendants.length - 1; index >= 0; index--) stack.push(descendants[index]);
  }
  assert.equal(ordered.length, rows.length);
  return ordered;
}

function boundaryPosition(boundaryId, type, positions, length) {
  if (type === 2) return 0;
  if (type === 3) return length;
  const position = positions.get(boundaryId);
  assert.notEqual(position, undefined);
  return position + (type === 1 ? 1 : 0);
}

function materialize() {
  const ordered = orderedCharacters();
  const positions = new Map(ordered.map((row, index) => [row.id, index]));
  const styles = db.prepare('SELECT * FROM style ORDER BY identity').all();
  const checkbox = new Map(db.prepare('SELECT * FROM checkbox').all()
    .map(row => [row.location_id, row.checked !== 0]));
  const text = [], characterRuns = [], paragraphRuns = [];
  let visibleIndex = 0;
  for (let index = 0; index < ordered.length; index++) {
    const row = ordered[index];
    if (!row.visible) continue;
    text.push(String.fromCodePoint(row.scalar));
    const characterStyle = {}, paragraphStyle = {};
    for (const style of styles) {
      const start = boundaryPosition(style.start_id, style.start_type, positions, ordered.length);
      const end = boundaryPosition(style.end_id, style.end_type, positions, ordered.length);
      if (index < start || index >= end) continue;
      Object.assign(style.paragraph ? paragraphStyle : characterStyle,
        JSON.parse(style.attributes));
    }
    if (paragraphStyle.decoratorStyle === 3 && checkbox.has(row.id)) {
      paragraphStyle.isChecked = checkbox.get(row.id);
    }
    appendRun(characterRuns, visibleIndex, characterStyle);
    appendRun(paragraphRuns, visibleIndex, paragraphStyle);
    visibleIndex++;
  }
  return { text: text.join(''), characterRuns, paragraphRuns };
}

function appendRun(runs, index, style) {
  if (Object.keys(style).length === 0) return;
  const previous = runs.at(-1);
  if (previous && previous.end === index &&
    JSON.stringify(previous.style) === JSON.stringify(style)) previous.end++;
  else runs.push({ start: index, end: index + 1, style });
}

function commit(identity, mutate, expected, fail = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const revision = db.prepare('SELECT revision FROM page').get().revision;
    mutate();
    db.prepare('INSERT INTO operation VALUES(?,?,1)').run(identity, 'text');
    const actual = materialize();
    assert.deepEqual(actual, expected);
    db.prepare('UPDATE block SET text=?,character_runs=?,paragraph_runs=?').run(
      actual.text, JSON.stringify(actual.characterRuns), JSON.stringify(actual.paragraphRuns));
    if (fail) throw new Error('injected styled text failure');
    db.prepare('UPDATE page SET revision=?').run(revision + 1);
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK'); throw error;
  }
}

commit(21, () => db.prepare('INSERT INTO character VALUES(?,?,?,1)')
  .run('21:7:0', '10:7:0', 88), {
  text: 'AXBC',
  characterRuns: [{ start: 2, end: 4, style: { bold: true } }],
  paragraphRuns: [{ start: 2, end: 3, style: { decoratorStyle: 3, isChecked: true } }],
});
commit(22, () => db.prepare("UPDATE character SET visible=0 WHERE id='10:7:1'").run(), {
  text: 'AXC', characterRuns: [{ start: 2, end: 3, style: { bold: true } }],
  paragraphRuns: [],
});
commit(23, () => {
  db.prepare("UPDATE character SET visible=0 WHERE id='21:7:0'").run();
  db.prepare("UPDATE character SET visible=1 WHERE id='10:7:1'").run();
}, {
  text: 'ABC', characterRuns: [{ start: 1, end: 3, style: { bold: true } }],
  paragraphRuns: [{ start: 1, end: 2, style: { decoratorStyle: 3, isChecked: true } }],
});

const beforeFailure = {
  revision: db.prepare('SELECT revision FROM page').get().revision,
  block: db.prepare('SELECT * FROM block').get(),
  operations: db.prepare('SELECT COUNT(*) count FROM operation').get().count,
};
assert.throws(() => commit(24, () =>
  db.prepare("UPDATE character SET visible=0 WHERE id='10:7:1'").run(), {
  text: 'AC', characterRuns: [{ start: 1, end: 2, style: { bold: true } }],
  paragraphRuns: [],
}, true), /injected styled text failure/);
assert.deepEqual({
  revision: db.prepare('SELECT revision FROM page').get().revision,
  block: db.prepare('SELECT * FROM block').get(),
  operations: db.prepare('SELECT COUNT(*) count FROM operation').get().count,
}, beforeFailure);
assert.equal(materialize().text, 'ABC');
db.close();

console.log('localStyledTextEdit=original-seqid-boundaries-insert-delete-revive-' +
  'paragraph-checkbox-clock-preview-ui-guard-single-revision-rollback');
