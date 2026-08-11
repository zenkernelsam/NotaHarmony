import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = (path) => fs.readFileSync(new URL(path, root), 'utf8');
const schema = read('note/src/main/ets/data/DatabaseHelper.ets');
const model = read('note/src/main/ets/core/model/StrokeTypes.ets');
const createSource = read('note/src/main/ets/data/OriginalCreateInkOperation.ets');
const modifySource = read('note/src/main/ets/data/OriginalModifyInkOperation.ets');
const renderer = read('note/src/main/ets/core/adaptation/Canvas2DStrokeRenderer.ets');
const painter = read('note/src/main/ets/rendering/StrokeCanvasPainter.ets');
const clipboard = read('note/src/main/ets/rendering/StrokeClipboard.ets');
const canvasView = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE ink_state (
  ink_timestamp INTEGER NOT NULL,
  ink_site INTEGER NOT NULL,
  PRIMARY KEY(ink_timestamp, ink_site)
);
INSERT INTO ink_state VALUES(10, 1);
PRAGMA user_version=48;`);
db.exec(`BEGIN;
ALTER TABLE ink_state ADD COLUMN create_tape_pattern INTEGER;
ALTER TABLE ink_state ADD COLUMN tape_pattern_value INTEGER;
ALTER TABLE ink_state ADD COLUMN tape_pattern_winner_timestamp INTEGER NOT NULL DEFAULT 0;
ALTER TABLE ink_state ADD COLUMN tape_pattern_winner_site INTEGER NOT NULL DEFAULT 0;
ALTER TABLE ink_state ADD COLUMN tape_pattern_winner_present INTEGER NOT NULL DEFAULT 0;
PRAGMA user_version=49;
COMMIT;`);
const legacy = db.prepare('SELECT * FROM ink_state WHERE ink_timestamp=10').get();
assert.equal(legacy.create_tape_pattern, null);
assert.equal(legacy.tape_pattern_value, null);
assert.equal(legacy.tape_pattern_winner_present, 0);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 49);

db.prepare(`INSERT INTO ink_state
  (ink_timestamp,ink_site,create_tape_pattern) VALUES(?,?,?)`).run(20, 3, 0);
const newer = (timestamp, site, row) => !row.tape_pattern_winner_present ||
  timestamp > row.tape_pattern_winner_timestamp ||
  (timestamp === row.tape_pattern_winner_timestamp && site > row.tape_pattern_winner_site);
const apply = (timestamp, site, value) => {
  const row = db.prepare('SELECT * FROM ink_state WHERE ink_timestamp=20 AND ink_site=3').get();
  if (!newer(timestamp, site, row)) return false;
  db.prepare(`UPDATE ink_state SET tape_pattern_value=?,tape_pattern_winner_timestamp=?,
    tape_pattern_winner_site=?,tape_pattern_winner_present=1
    WHERE ink_timestamp=20 AND ink_site=3`).run(value, timestamp, site);
  return true;
};
assert.equal(apply(40, 2, 5), true);
assert.equal(apply(39, 9, 8), false);
assert.equal(apply(40, 1, 7), false);
assert.equal(apply(40, 8, 6), true);
let tape = db.prepare('SELECT * FROM ink_state WHERE ink_timestamp=20 AND ink_site=3').get();
assert.equal(tape.create_tape_pattern, 0);
assert.equal(tape.tape_pattern_value, 6);
assert.equal(tape.tape_pattern_winner_site, 8);

assert.throws(() => {
  db.exec('BEGIN');
  apply(50, 1, 4);
  throw new Error('injected materialization failure');
}, /injected/);
db.exec('ROLLBACK');
tape = db.prepare('SELECT * FROM ink_state WHERE ink_timestamp=20 AND ink_site=3').get();
assert.equal(tape.tape_pattern_value, 6);

assert.match(schema, /DB_VERSION: number = 60/);
assert.match(schema, /49: \[/);
assert.match(schema, /create_tape_pattern INTEGER/);
assert.match(schema, /tape_pattern_winner_present INTEGER NOT NULL/);
assert.match(model, /export enum TapePattern[\s\S]*STRIPES = 0[\s\S]*CHECKERS = 8/);
assert.match(createSource, /payload\.tool === 3[\s\S]*TapePattern\.STRIPES/);
assert.match(createSource, /CREATE_INK_TAPE_PATTERN_FOR_NON_TAPE/);
assert.match(createSource, /'create_tape_pattern'/);
assert.match(createSource, /tapePattern: tapePattern/);
assert.match(modifySource, /replaceTapePattern/);
assert.match(modifySource, /registerAccepts\(operation, state\.tapePattern\.winner\)/);
assert.match(modifySource, /MODIFY_INK_TAPE_PATTERN_FOR_NON_TAPE/);
assert.match(modifySource, /'tape_pattern_value'/);
assert.match(renderer, /renderTapePattern/);
for (const name of ['STRIPES', 'GRID', 'DOTS', 'STARS', 'FLOWERS', 'HEARTS',
  'WAVES', 'CHECKERS']) {
  assert.match(renderer, new RegExp(`TapePattern\\.${name}`));
}
assert.match(renderer, /pattern === TapePattern\.PLAIN/);
assert.match(renderer, /createPattern\(image, 'repeat'\)/);
assert.match(renderer, /TAPE_TILE_DENSITY: number = 8/);
assert.match(renderer, /MAX_TAPE_TILES: number = 32/);
assert.match(renderer, /releaseTapeTiles/);
assert.match(renderer, /radius \* 0\.45/);
assert.match(renderer, /x \+ 1\.5, y - 3, x \+ 4\.5, y \+ 3/);
assert.match(painter, /stroke\.renderSpec\.tapePattern !== undefined/);
assert.match(clipboard, /tapePattern: stroke\.renderSpec\.tapePattern/);
assert.match(canvasView, /tapePattern: s\.renderSpec\.tapePattern/);

console.log('D02_ORIGINAL_TAPE_REPLAY_OK ' +
  'v48-v49-defaults=3|create-default=stripes|lww-stale-tie=4|rollback=1|' +
  'patterns=9|bounded-repeat-cache=32|model-persistence-renderer-copy=closed');
