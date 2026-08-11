import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const read = value => fs.readFileSync(new URL('../../../' + value, import.meta.url), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const originalU5j = fs.readFileSync(originalRoot + 'u5j.java', 'utf8');
const originalA1j = fs.readFileSync(originalRoot + 'a1j.java', 'utf8');
const originalLe8 = fs.readFileSync(originalRoot + 'le8.java', 'utf8');
const encoder = read('note/src/main/ets/data/OriginalModifyShapePayloadEncoder.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const renderer = read('note/src/main/ets/rendering/ShapeCanvasRenderer.ets');
const toolbar = read('note/src/main/ets/ui/editor/EditorToolbar.ets');
const payloadFixtures = read('note/src/test/OriginalCreateInkPayloadEncoder.test.ets');
const persistenceFixtures = read('note/src/test/StrokePersistence.test.ets');
const rendererFixtures = read('note/src/test/RendererStyle.test.ets');

assert.match(originalU5j,
  /public static le8 x\(x09 x09Var, List list, cxc cxcVar, fqa fqaVar, v4d v4dVar, t16 t16Var/);
assert.match(originalU5j, /return a1j\.a\([\s\S]*t16Var2/);
assert.match(originalA1j, /aVarA\.c\(8, t16Var\.I, 0\)/);
assert.match(originalLe8, /Shapes cannot use variable width ink/);

assert.match(encoder, /style: number \| null/);
assert.match(encoder, /fields\[8\] = update\.style === null \? 0 : 8/);
assert.match(encoder, /update\.style < 1 \|\| update\.style > 3/);
assert.match(persistence, /styleChanged: boolean = before\.originalStyle !== after\.originalStyle/);
assert.match(persistence, /expectedStyle: number = before\.originalStyle === undefined/);
assert.match(persistence, /style: styleChanged \? after\.originalStyle : null/);
assert.match(persistence, /expectedStyles: \[expectedStyle\]/);
assert.match(canvas, /style === InkStyle\.VARIABLE_WIDTH[\s\S]*continue/);
assert.match(canvas, /replacement\.originalStyle = style === InkStyle\.FIXED_WIDTH \? 1/);
assert.match(toolbar,
  /style !== BrushStyle\.TAPER \|\| this\.selectionVariableStyleEnabled/);
assert.match(renderer, /shape\.originalStyle === 2[\s\S]*2 \* shape\.strokeWidth/);
assert.match(renderer, /shape\.originalStyle === 3[\s\S]*0\.001 \* shape\.strokeWidth/);
assert.match(payloadFixtures, /expect\(highlighter\.style\)\.assertEqual\(2\)/);
assert.match(payloadFixtures, /style: 0[\s\S]*assertThrow/);
assert.match(persistenceFixtures, /expectedStyles\[0\]\)\.assertEqual\(2\)/);
assert.match(rendererFixtures, /renders Shape DASH and DOTS with original fixed-width spacing/);

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE shape(id TEXT PRIMARY KEY,style INTEGER NOT NULL);
  CREATE TABLE operation(seq INTEGER PRIMARY KEY AUTOINCREMENT,style INTEGER NOT NULL);
  CREATE TABLE history(seq INTEGER PRIMARY KEY AUTOINCREMENT,before_style INTEGER,after_style INTEGER);
  CREATE TABLE page(id INTEGER PRIMARY KEY,revision INTEGER NOT NULL);
  INSERT INTO shape VALUES('op:20:2',1); INSERT INTO page VALUES(1,0);`);

function modifyStyle(expected, next, fail = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const row = db.prepare('SELECT style FROM shape WHERE id=?').get('op:20:2');
    if (row.style !== expected) throw new Error('stale Shape style source');
    db.prepare('UPDATE shape SET style=? WHERE id=?').run(next, 'op:20:2');
    db.prepare('INSERT INTO operation(style) VALUES(?)').run(next);
    if (fail) throw new Error('injected Shape style history failure');
    db.prepare('INSERT INTO history(before_style,after_style) VALUES(?,?)').run(expected, next);
    db.exec('UPDATE page SET revision=revision+1 WHERE id=1');
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

modifyStyle(1, 2);
assert.equal(db.prepare('SELECT style FROM shape').get().style, 2);
assert.equal(db.prepare('SELECT revision FROM page').get().revision, 1);
assert.throws(() => modifyStyle(1, 3), /stale Shape style source/);
assert.throws(() => modifyStyle(2, 3, true), /injected Shape style history failure/);
assert.equal(db.prepare('SELECT style FROM shape').get().style, 2);
assert.equal(db.prepare('SELECT COUNT(*) AS count FROM operation').get().count, 1);
modifyStyle(2, 1);
assert.equal(db.prepare('SELECT style FROM shape').get().style, 1);
assert.equal(db.prepare('SELECT revision FROM page').get().revision, 2);
db.close();

console.log('localModifyShapeStyle=type19-field8-source-style-preflight-' +
  'selection-render-undo-rollback');
