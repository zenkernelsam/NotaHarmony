import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const schema = read('note/src/main/ets/data/DatabaseHelper.ets');
const textReducer = read('note/src/main/ets/data/OriginalInsertTextOperation.ets');
const styleReducer = read('note/src/main/ets/data/OriginalRichTextStyleOperation.ets');
const checkboxReducer = read('note/src/main/ets/data/OriginalUpdateCheckboxOperation.ets');
const shapeReducer = read('note/src/main/ets/data/OriginalShapeGroupOperation.ets');
const packageSpec = read('note/src/main/ets/data/NotePackageSpec.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');

const characterV57 = extractTemplate(schema, 'DDL_ORIGINAL_TEXT_CHARACTER_V57');
const styleV57 = extractTemplate(schema, 'DDL_ORIGINAL_TEXT_STYLE_OPERATION_V57');

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys=ON; PRAGMA user_version=56;
    CREATE TABLE note_meta(id TEXT PRIMARY KEY);
    CREATE TABLE original_element_z_index(
      note_id TEXT NOT NULL, element_timestamp INTEGER NOT NULL,
      element_site_id INTEGER NOT NULL, kind INTEGER NOT NULL,
      PRIMARY KEY(note_id,element_timestamp,element_site_id),
      FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    CREATE TABLE original_block_state(
      note_id TEXT NOT NULL, block_timestamp INTEGER NOT NULL,
      block_site_id INTEGER NOT NULL, block_type INTEGER NOT NULL,
      PRIMARY KEY(note_id,block_timestamp,block_site_id),
      FOREIGN KEY(note_id,block_timestamp,block_site_id)
        REFERENCES original_element_z_index(note_id,element_timestamp,element_site_id)
        ON DELETE CASCADE);
    CREATE TABLE original_text_character(
      note_id TEXT NOT NULL, block_timestamp INTEGER NOT NULL, block_site_id INTEGER NOT NULL,
      char_timestamp INTEGER NOT NULL, char_site_id INTEGER NOT NULL, char_index INTEGER NOT NULL,
      parent_timestamp INTEGER, parent_site_id INTEGER, parent_index INTEGER,
      unicode_scalar INTEGER NOT NULL, visible INTEGER NOT NULL DEFAULT 1,
      visibility_winner_timestamp INTEGER, visibility_winner_site_id INTEGER,
      visibility_winner_present INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY(note_id,char_timestamp,char_site_id,char_index),
      FOREIGN KEY(note_id,block_timestamp,block_site_id)
        REFERENCES original_block_state(note_id,block_timestamp,block_site_id)
        ON DELETE CASCADE);
    CREATE TABLE original_text_style_operation(
      note_id TEXT NOT NULL, block_timestamp INTEGER NOT NULL, block_site_id INTEGER NOT NULL,
      operation_timestamp INTEGER NOT NULL, operation_site_id INTEGER NOT NULL,
      paragraph INTEGER NOT NULL, clear_all INTEGER NOT NULL,
      start_timestamp INTEGER NOT NULL, start_site_id INTEGER NOT NULL,
      start_index INTEGER NOT NULL, start_type INTEGER NOT NULL,
      end_timestamp INTEGER NOT NULL, end_site_id INTEGER NOT NULL,
      end_index INTEGER NOT NULL, end_type INTEGER NOT NULL, attributes_json TEXT NOT NULL,
      PRIMARY KEY(note_id,operation_timestamp,operation_site_id),
      FOREIGN KEY(note_id,block_timestamp,block_site_id)
        REFERENCES original_block_state(note_id,block_timestamp,block_site_id)
        ON DELETE CASCADE);
    INSERT INTO note_meta VALUES('n');
    INSERT INTO original_element_z_index VALUES('n',20,2,1);
    INSERT INTO original_block_state VALUES('n',20,2,0);
    INSERT INTO original_text_character VALUES
      ('n',20,2,100,7,0,NULL,NULL,NULL,65,1,200,1,1);
    INSERT INTO original_text_style_operation VALUES
      ('n',20,2,201,1,0,0,100,7,0,0,100,7,0,1,'{"bold":true}');`);
  return db;
}

function migrateV57(db, fail = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(characterV57);
    db.exec(`INSERT INTO original_text_character_v57
      SELECT * FROM original_text_character`);
    db.exec('DROP TABLE original_text_character');
    db.exec('ALTER TABLE original_text_character_v57 RENAME TO original_text_character');
    if (fail) throw new Error('injected v57 migration failure');
    db.exec(styleV57);
    db.exec(`INSERT INTO original_text_style_operation_v57
      SELECT * FROM original_text_style_operation`);
    db.exec('DROP TABLE original_text_style_operation');
    db.exec(`ALTER TABLE original_text_style_operation_v57
      RENAME TO original_text_style_operation`);
    db.exec('PRAGMA user_version=57; COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const db = database();
migrateV57(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 57);
assert.equal(db.prepare(`SELECT unicode_scalar FROM original_text_character
  WHERE block_timestamp=20`).get().unicode_scalar, 65);
assert.equal(db.prepare(`SELECT attributes_json FROM original_text_style_operation
  WHERE block_timestamp=20`).get().attributes_json, '{"bold":true}');

// A Shape owns the same character/style CRDT through its element identity.
db.exec(`INSERT INTO original_element_z_index VALUES('n',30,3,2);
  INSERT INTO original_text_character VALUES
    ('n',30,3,110,8,0,NULL,NULL,NULL,128512,1,NULL,NULL,0);
  INSERT INTO original_text_style_operation VALUES
    ('n',30,3,210,8,0,0,110,8,0,0,110,8,0,1,'{"italic":true}');`);
assert.equal(db.prepare(`SELECT unicode_scalar FROM original_text_character
  WHERE block_timestamp=30`).get().unicode_scalar, 128512);
assert.equal(db.prepare(`SELECT COUNT(*) count FROM original_text_style_operation
  WHERE block_timestamp=30`).get().count, 1);

// An identity that is not a materialized element remains outside the FK domain.
assert.throws(() => db.exec(`INSERT INTO original_text_character VALUES
  ('n',999,9,120,9,0,NULL,NULL,NULL,66,1,NULL,NULL,0)`), /FOREIGN KEY/);

// Deleting the owning Shape or note cascades its shared RichText state.
db.exec(`DELETE FROM original_element_z_index
  WHERE note_id='n' AND element_timestamp=30 AND element_site_id=3`);
assert.equal(db.prepare(`SELECT COUNT(*) count FROM original_text_character
  WHERE block_timestamp=30`).get().count, 0);
assert.equal(db.prepare(`SELECT COUNT(*) count FROM original_text_style_operation
  WHERE block_timestamp=30`).get().count, 0);
db.exec("DELETE FROM note_meta WHERE id='n'");
assert.equal(db.prepare('SELECT COUNT(*) count FROM original_text_character').get().count, 0);
assert.equal(db.prepare('SELECT COUNT(*) count FROM original_text_style_operation').get().count, 0);
db.close();

const failed = database();
assert.throws(() => migrateV57(failed, true), /injected v57 migration failure/);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version, 56);
assert.equal(failed.prepare(`SELECT COUNT(*) count FROM original_text_character`).get().count, 1);
assert.equal(failed.prepare(`SELECT COUNT(*) count FROM original_text_style_operation`).get().count, 1);
assert.equal(failed.prepare(`SELECT COUNT(*) count FROM sqlite_master
  WHERE type='table' AND name LIKE '%_v57'`).get().count, 0);
failed.close();

assert.match(schema, /DB_VERSION: number = 59/);
assert.match(schema, /57: \[[\s\S]*original_text_character_v57[\s\S]*original_text_style_operation_v57/);
assert.match(characterV57, /REFERENCES original_element_z_index/);
assert.match(styleV57, /REFERENCES original_element_z_index/);
assert.match(textReducer, /element\.kind IN \(\?, \?\)/);
assert.match(textReducer, /PageElementKind\.TEXT, PageElementKind\.SHAPE/);
assert.match(textReducer, /target\.kind === PageElementKind\.SHAPE/);
assert.match(textReducer, /original_deleted_page_element/);
assert.match(textReducer, /original_deleted_entity/);
assert.match(styleReducer, /cloneRichTextElement\(text, target\.kind\)/);
assert.match(checkboxReducer, /target\.kind !== PageElementKind\.TEXT/);
assert.match(shapeReducer, /copyShapeRichText\(shapeElement, snapshots\[index\]\)/);
assert.match(shapeReducer, /richText: '', characterStyleRuns: \[\], paragraphStyleRuns: \[\]/);
assert.match(packageSpec, /typeof shape\.richText !== 'string' \|\|[\s\S]*isValidRichTextRuns\(shape,/);
assert.match(persistence, /parsed\.kind === 'text' \|\| parsed\.kind === 'shape'/);
assert.match(persistence, /foldSearchText\(element\.data\.richText \?\? ''\)/);

console.log('D02_SHAPE_RICH_TEXT_REPLAY_OK ' +
  'v56-v57-preserve=2|migration-rollback=4|shape-character-style=2|' +
  'non-element-fk=1|element-note-cascade=4|insert-visibility-style=3|' +
  'checkbox-shape-rejected=1|modify-shape-preserves-text=1|' +
  'hidden-archived=2|package-search=2');

function extractTemplate(source, name) {
  const match = source.match(new RegExp('(?:export )?const ' + name +
    ': string = `([\\s\\S]*?)`;'));
  assert(match, `${name} missing`);
  return match[1];
}
