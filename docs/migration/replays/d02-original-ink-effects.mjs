import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const U64_MAX = '18446744073709551615';

function u16(bytes, offset) { return bytes[offset] | (bytes[offset + 1] << 8); }
function u32(bytes, offset) {
  return (bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16) |
    (bytes[offset + 3] << 24)) >>> 0;
}
function i32(bytes, offset) {
  return new DataView(bytes.buffer, bytes.byteOffset + offset, 4).getInt32(0, true);
}
function w16(bytes, offset, value) { bytes[offset] = value; bytes[offset + 1] = value >>> 8; }
function w32(bytes, offset, value) {
  bytes[offset] = value; bytes[offset + 1] = value >>> 8;
  bytes[offset + 2] = value >>> 16; bytes[offset + 3] = value >>> 24;
}
function w64(bytes, offset, decimal) {
  let value = BigInt(decimal);
  for (let index = 0; index < 8; index++) {
    bytes[offset + index] = Number(value & 255n);
    value >>= 8n;
  }
}
function r64(bytes, offset) {
  let value = 0n;
  for (let index = 7; index >= 0; index--) value = (value << 8n) | BigInt(bytes[offset + index]);
  return value.toString();
}

class Builder {
  constructor() { this.bytes = new Uint8Array(2048); this.cursor = 4; }
  align(size) { while (this.cursor % size) this.cursor++; }
  table(fields, size) {
    this.align(4);
    const vtable = this.cursor; this.cursor += 4 + fields.length * 2;
    this.align(4);
    const table = this.cursor; this.cursor += size;
    w16(this.bytes, vtable, 4 + fields.length * 2); w16(this.bytes, vtable + 2, size);
    fields.forEach((value, index) => w16(this.bytes, vtable + 4 + index * 2, value));
    w32(this.bytes, table, table - vtable);
    return table;
  }
  pointer(slot, target) { assert(target > slot); w32(this.bytes, slot, target - slot); }
  identities(values) {
    this.align(4); const vector = this.cursor; this.cursor += 4 + values.length * 8;
    w32(this.bytes, vector, values.length);
    values.forEach((value, index) => {
      const item = vector + 4 + index * 8;
      w16(this.bytes, item, value.site); w32(this.bytes, item + 4, value.timestamp);
    });
    return vector;
  }
  finish(root) { w32(this.bytes, 0, root); return this.bytes.slice(0, this.cursor); }
}

class Table {
  constructor(bytes, table) {
    this.bytes = bytes; this.table = table; this.vtable = table - i32(bytes, table);
    this.vtableSize = u16(bytes, this.vtable);
  }
  offset(field) {
    const entry = this.vtable + 4 + field * 2;
    return entry + 2 <= this.vtable + this.vtableSize ? u16(this.bytes, entry) : 0;
  }
  nested(field) {
    const offset = this.offset(field); assert.notEqual(offset, 0);
    const pointer = this.table + offset;
    return new Table(this.bytes, pointer + u32(this.bytes, pointer));
  }
  uint8(field, fallback) {
    const offset = this.offset(field); return offset === 0 ? fallback : this.bytes[this.table + offset];
  }
  uint64(field, fallback = null) {
    const offset = this.offset(field); return offset === 0 ? fallback : r64(this.bytes, this.table + offset);
  }
  identityVector(field) {
    const offset = this.offset(field); assert.notEqual(offset, 0);
    const pointer = this.table + offset, vector = pointer + u32(this.bytes, pointer);
    const result = [], count = u32(this.bytes, vector);
    for (let index = 0; index < count; index++) {
      const item = vector + 4 + index * 8;
      result.push({ timestamp: u32(this.bytes, item + 4), site: u16(this.bytes, item) });
    }
    return result;
  }
}

function envelope(payloadType, fields, size, writePayload) {
  const builder = new Builder();
  const root = builder.table([4, 12, 20, 0, 28, 32], 36);
  w16(builder.bytes, root + 4, 7); w32(builder.bytes, root + 8, 99);
  builder.bytes[root + 28] = payloadType;
  const payload = builder.table(fields, size); builder.pointer(root + 32, payload);
  writePayload(builder, payload);
  return builder.finish(root);
}

function createFixture(effects, tinted) {
  const fields = new Array(20).fill(0); fields[18] = 8; fields[19] = 16;
  return envelope(15, fields, 24, (builder, payload) => {
    w64(builder.bytes, payload + 8, effects); builder.bytes[payload + 16] = tinted ? 1 : 0;
  });
}

function modifyFixture(targets, { tape, effects, tinted }) {
  const fields = new Array(19).fill(0); fields[0] = 4;
  if (tape !== undefined) fields[16] = 8;
  if (effects !== undefined) fields[17] = 16;
  if (tinted !== undefined) fields[18] = 24;
  return envelope(17, fields, 28, (builder, payload) => {
    builder.pointer(payload + 4, builder.identities(targets));
    if (tape !== undefined) builder.bytes[payload + 8] = tape;
    if (effects !== undefined) w64(builder.bytes, payload + 16, effects);
    if (tinted !== undefined) builder.bytes[payload + 24] = tinted ? 1 : 0;
  });
}

function payloadTable(raw, expectedType) {
  const root = new Table(raw, u32(raw, 0));
  assert.equal(root.uint8(4, -1), expectedType);
  return root.nested(5);
}

const createDecoded = payloadTable(createFixture(U64_MAX, false), 15);
assert.equal(createDecoded.uint64(18, '0'), U64_MAX);
assert.equal(createDecoded.uint8(19, 1), 0);
const targetA = { timestamp: 20, site: 2 }, targetB = { timestamp: 21, site: 3 };
const modifyDecoded = payloadTable(modifyFixture([targetA, targetB], {
  tape: 8, effects: '3', tinted: false,
}), 17);
assert.deepEqual(modifyDecoded.identityVector(0), [targetA, targetB]);
assert.equal(modifyDecoded.uint8(16, -1), 8);
assert.equal(modifyDecoded.uint64(17), '3');
assert.equal(modifyDecoded.uint8(18, 1), 0);

function validU64(value) {
  return typeof value === 'string' && /^(0|[1-9][0-9]{0,19})$/.test(value) &&
    (value.length < 20 || value <= U64_MAX);
}

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA user_version=47;
    CREATE TABLE ink_state(
      ink_timestamp INTEGER NOT NULL, ink_site INTEGER NOT NULL, hidden INTEGER NOT NULL DEFAULT 0,
      style_phase REAL NOT NULL DEFAULT 0, phase_winner_timestamp INTEGER NOT NULL DEFAULT 0,
      phase_winner_site INTEGER NOT NULL DEFAULT 0, phase_winner_present INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY(ink_timestamp,ink_site));
    CREATE TABLE element(
      ink_timestamp INTEGER NOT NULL, ink_site INTEGER NOT NULL, hidden INTEGER NOT NULL,
      payload TEXT NOT NULL, PRIMARY KEY(ink_timestamp,ink_site));
    CREATE TABLE page(page_id TEXT PRIMARY KEY,revision INTEGER NOT NULL);
    INSERT INTO page VALUES('p1',1);
    INSERT INTO ink_state(ink_timestamp,ink_site) VALUES(10,1);`);
  return db;
}

function migrate(db, inject = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(`ALTER TABLE ink_state ADD COLUMN create_ink_effects TEXT NOT NULL DEFAULT '0';
      ALTER TABLE ink_state ADD COLUMN create_ink_effects_tinted INTEGER NOT NULL DEFAULT 1;
      ALTER TABLE ink_state ADD COLUMN ink_effects_value TEXT;
      ALTER TABLE ink_state ADD COLUMN ink_effects_winner_timestamp INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE ink_state ADD COLUMN ink_effects_winner_site INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE ink_state ADD COLUMN ink_effects_winner_present INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE ink_state ADD COLUMN ink_effects_tinted_value INTEGER;
      ALTER TABLE ink_state ADD COLUMN ink_effects_tinted_winner_timestamp INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE ink_state ADD COLUMN ink_effects_tinted_winner_site INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE ink_state ADD COLUMN ink_effects_tinted_winner_present INTEGER NOT NULL DEFAULT 0;`);
    if (inject) throw new Error('injected migration');
    db.exec('PRAGMA user_version=48; COMMIT');
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

function createInk(db, identity, { effects, tinted, tool = 'PEN', hidden = false, phase = 0 }) {
  if (!validU64(effects)) return 'INVALID_U64';
  if (effects !== '0' && tool !== 'PEN' && tool !== 'HIGHLIGHTER') return 'INVALID_TOOL';
  if (effects === '0' && !tinted) return 'INVALID_TINT';
  const existing = db.prepare('SELECT * FROM ink_state WHERE ink_timestamp=? AND ink_site=?')
    .get(identity.timestamp, identity.site);
  const payload = JSON.stringify({ effects, tinted, phase });
  if (existing) {
    const element = db.prepare('SELECT payload,hidden FROM element WHERE ink_timestamp=? AND ink_site=?')
      .get(identity.timestamp, identity.site);
    const effectiveEffects = existing.ink_effects_winner_present ?
      existing.ink_effects_value : existing.create_ink_effects;
    const effectiveTinted = Boolean(existing.ink_effects_tinted_winner_present ?
      existing.ink_effects_tinted_value : existing.create_ink_effects_tinted);
    const effectivePhase = existing.phase_winner_present ? existing.style_phase : phase;
    const effectivePayload = JSON.stringify({ effects: effectiveEffects,
      tinted: effectiveTinted, phase: effectivePhase });
    return existing.create_ink_effects === effects &&
      Boolean(existing.create_ink_effects_tinted) === tinted &&
      element?.payload === effectivePayload && Boolean(element.hidden) === hidden ?
      'RETRY' : 'CONFLICT';
  }
  db.prepare(`INSERT INTO ink_state(
      ink_timestamp,ink_site,hidden,style_phase,create_ink_effects,create_ink_effects_tinted)
    VALUES(?,?,?,?,?,?)`).run(identity.timestamp, identity.site, hidden ? 1 : 0,
    phase, effects, tinted ? 1 : 0);
  db.prepare('INSERT INTO element VALUES(?,?,?,?)').run(identity.timestamp, identity.site,
    hidden ? 1 : 0, payload);
  return 'CREATED';
}

function newer(timestamp, site, state, prefix) {
  return !state[`${prefix}_winner_present`] || timestamp > state[`${prefix}_winner_timestamp`] ||
    (timestamp === state[`${prefix}_winner_timestamp`] && site > state[`${prefix}_winner_site`]);
}

function currentValue(state, prefix, base) {
  return state[`${prefix}_winner_present`] ? state[`${prefix}_value`] : base;
}

function applyModify(db, timestamp, site, targets, update, inject = false) {
  if (update.tape !== undefined) return 'TAPE_DEFERRED';
  if (update.effects !== undefined && !validU64(update.effects)) return 'INVALID_U64';
  db.exec('BEGIN IMMEDIATE');
  try {
    const plans = [];
    for (const target of targets) {
      const state = db.prepare('SELECT * FROM ink_state WHERE ink_timestamp=? AND ink_site=?')
        .get(target.timestamp, target.site);
      const element = db.prepare('SELECT * FROM element WHERE ink_timestamp=? AND ink_site=?')
        .get(target.timestamp, target.site);
      if (!state || !element) { db.exec('ROLLBACK'); return 'MISSING'; }
      let current;
      try {
        current = JSON.parse(element.payload);
      } catch (_error) {
        db.exec('ROLLBACK'); return 'DIVERGED';
      }
      const expectedEffects = currentValue(state, 'ink_effects', state.create_ink_effects);
      const expectedTint = Boolean(currentValue(state, 'ink_effects_tinted',
        state.create_ink_effects_tinted));
      if (current.effects !== expectedEffects || current.tinted !== expectedTint ||
        current.phase !== state.style_phase) { db.exec('ROLLBACK'); return 'DIVERGED'; }
      for (const [prefix, value] of [['ink_effects', update.effects],
        ['ink_effects_tinted', update.tinted === undefined ? undefined : update.tinted ? 1 : 0]]) {
        if (value === undefined || !state[`${prefix}_winner_present`] ||
          state[`${prefix}_winner_timestamp`] !== timestamp || state[`${prefix}_winner_site`] !== site) continue;
        if (state[`${prefix}_value`] !== value) throw new Error(`identity conflict ${prefix}`);
      }
      const replaceEffects = update.effects !== undefined && newer(timestamp, site, state, 'ink_effects');
      const replaceTint = update.tinted !== undefined && newer(timestamp, site, state, 'ink_effects_tinted');
      const replacePhase = update.phase !== undefined && newer(timestamp, site, state, 'phase');
      if (replaceEffects || replaceTint || replacePhase) {
        plans.push({ target, state, current, replaceEffects, replaceTint, replacePhase });
      }
    }
    for (const plan of plans) {
      const next = { ...plan.current };
      if (plan.replaceEffects) next.effects = update.effects;
      if (plan.replaceTint) next.tinted = update.tinted;
      if (plan.replacePhase) next.phase = update.phase;
      db.prepare('UPDATE element SET payload=? WHERE ink_timestamp=? AND ink_site=?')
        .run(JSON.stringify(next), plan.target.timestamp, plan.target.site);
      if (plan.replaceEffects) db.prepare(`UPDATE ink_state SET ink_effects_value=?,
        ink_effects_winner_timestamp=?,ink_effects_winner_site=?,ink_effects_winner_present=1
        WHERE ink_timestamp=? AND ink_site=?`).run(update.effects, timestamp, site,
        plan.target.timestamp, plan.target.site);
      if (plan.replaceTint) db.prepare(`UPDATE ink_state SET ink_effects_tinted_value=?,
        ink_effects_tinted_winner_timestamp=?,ink_effects_tinted_winner_site=?,
        ink_effects_tinted_winner_present=1 WHERE ink_timestamp=? AND ink_site=?`)
        .run(update.tinted ? 1 : 0, timestamp, site, plan.target.timestamp, plan.target.site);
      if (plan.replacePhase) db.prepare(`UPDATE ink_state SET style_phase=?,phase_winner_timestamp=?,
        phase_winner_site=?,phase_winner_present=1 WHERE ink_timestamp=? AND ink_site=?`)
        .run(update.phase, timestamp, site, plan.target.timestamp, plan.target.site);
    }
    if (inject) throw new Error('injected apply');
    if (plans.some((plan) => !plan.state.hidden)) db.exec("UPDATE page SET revision=revision+1 WHERE page_id='p1'");
    db.exec('COMMIT'); return plans.length ? 'APPLIED' : 'STALE';
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

const db = database(); migrate(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 48);
const legacy = db.prepare('SELECT * FROM ink_state WHERE ink_timestamp=10').get();
assert.equal(legacy.create_ink_effects, '0'); assert.equal(legacy.create_ink_effects_tinted, 1);
assert.equal(legacy.ink_effects_winner_present, 0);

assert.equal(createInk(db, targetA, { effects: '1', tinted: false, phase: 7.5 }), 'CREATED');
assert.equal(createInk(db, targetA, { effects: '1', tinted: false, phase: 7.5 }), 'RETRY');
assert.equal(createInk(db, targetA, { effects: '2', tinted: false, phase: 7.5 }), 'CONFLICT');
assert.equal(createInk(db, targetB, { effects: U64_MAX, tinted: true, hidden: true }), 'CREATED');
assert.equal(createInk(db, { timestamp: 22, site: 4 },
  { effects: '3', tinted: true, tool: 'PENCIL' }), 'INVALID_TOOL');
assert.equal(createInk(db, { timestamp: 23, site: 4 }, { effects: '0', tinted: false }), 'INVALID_TINT');
assert.equal(createInk(db, { timestamp: 24, site: 4 },
  { effects: '2', tinted: false, tool: 'HIGHLIGHTER' }), 'CREATED');

assert.equal(applyModify(db, 5, 1, [targetA], { effects: '3' }), 'APPLIED');
assert.equal(applyModify(db, 5, 2, [targetA], { effects: '9223372036854775808' }), 'APPLIED');
assert.equal(applyModify(db, 4, 65535, [targetA], { effects: '2' }), 'STALE');
assert.equal(applyModify(db, 6, 1, [targetA], { tinted: false }), 'APPLIED');
// Independent registers may legally materialize effects=0,tinted=false.
assert.equal(applyModify(db, 7, 1, [targetA], { effects: '0' }), 'APPLIED');
assert.deepEqual(JSON.parse(db.prepare('SELECT payload FROM element WHERE ink_timestamp=20').get().payload),
  { effects: '0', tinted: false, phase: 7.5 });
assert.equal(applyModify(db, 8, 1, [targetA], { phase: -3.25 }), 'APPLIED');
assert.equal(JSON.parse(db.prepare('SELECT payload FROM element WHERE ink_timestamp=20').get().payload).phase,
  -3.25);
assert.equal(createInk(db, targetA, { effects: '1', tinted: false, phase: 7.5 }), 'RETRY');
assert.equal(applyModify(db, 9, 1, [targetB], { effects: '2', tinted: false }), 'APPLIED');
assert.equal(db.prepare('SELECT hidden FROM element WHERE ink_timestamp=21').get().hidden, 1);
assert.equal(JSON.parse(db.prepare('SELECT payload FROM element WHERE ink_timestamp=21').get().payload).effects,
  '2');
assert.equal(applyModify(db, 10, 1, [targetA], { tape: 4 }), 'TAPE_DEFERRED');

assert.throws(() => applyModify(db, 7, 1, [targetA], { effects: '3' }), /identity conflict/);
const beforeA = db.prepare('SELECT payload FROM element WHERE ink_timestamp=20').get().payload;
db.prepare("UPDATE element SET payload='bad' WHERE ink_timestamp=21").run();
assert.equal(applyModify(db, 11, 1, [targetA, targetB], { effects: '1' }), 'DIVERGED');
assert.equal(db.prepare('SELECT payload FROM element WHERE ink_timestamp=20').get().payload, beforeA);
db.prepare('UPDATE element SET payload=? WHERE ink_timestamp=21').run(
  JSON.stringify({ effects: '2', tinted: false, phase: 0 }));
assert.throws(() => applyModify(db, 12, 1, [targetA, targetB], { effects: '1' }, true),
  /injected apply/);
assert.equal(db.prepare('SELECT payload FROM element WHERE ink_timestamp=20').get().payload, beforeA);

const failedMigration = database();
assert.throws(() => migrate(failedMigration, true), /injected migration/);
assert.equal(failedMigration.prepare('PRAGMA user_version').get().user_version, 47);

const createSource = fs.readFileSync(new URL(
  '../../../note/src/main/ets/data/OriginalCreateInkOperation.ets', import.meta.url), 'utf8');
const modifySource = fs.readFileSync(new URL(
  '../../../note/src/main/ets/data/OriginalModifyInkOperation.ets', import.meta.url), 'utf8');
const schema = fs.readFileSync(new URL(
  '../../../note/src/main/ets/data/DatabaseHelper.ets', import.meta.url), 'utf8');
const model = fs.readFileSync(new URL(
  '../../../note/src/main/ets/core/model/StrokeTypes.ets', import.meta.url), 'utf8');
const clipboard = fs.readFileSync(new URL(
  '../../../note/src/main/ets/rendering/StrokeClipboard.ets', import.meta.url), 'utf8');
const packageSpec = fs.readFileSync(new URL(
  '../../../note/src/main/ets/data/NotePackageSpec.ets', import.meta.url), 'utf8');
const canvasView = fs.readFileSync(new URL(
  '../../../note/src/main/ets/ui/editor/NoteCanvasView.ets', import.meta.url), 'utf8');

assert.match(createSource, /inkEffects: table\.readUint64Decimal\(18, '0'\)/);
assert.match(createSource, /inkEffectsTinted: table\.readUint8\(19, 1\) !== 0/);
assert.match(createSource, /'create_ink_effects': payload\.inkEffects/);
assert.match(createSource, /inkEffectPhase: styleEntry === undefined \? 0/);
assert.match(createSource, /ink_effects_winner_present/);
assert.match(createSource, /style_map_winner_present/);
assert.match(createSource, /CREATE_INK_EFFECT_TOOL_UNSUPPORTED/);
assert.match(modifySource, /inkEffects: table\.readUint64Decimal\(17\)/);
assert.match(modifySource, /inkEffectsTinted: table\.hasField\(18\)/);
assert.match(modifySource, /registerAccepts\(operation, state\.inkEffects\.winner\)/);
assert.match(modifySource, /registerAccepts\(operation, state\.inkEffectsTinted\.winner\)/);
assert.match(modifySource, /inkEffectPhase: styleMap\.length === 0 \? 0/);
assert.match(modifySource, /MODIFY_INK_EFFECT_PHASE_STATE_DIVERGED/);
assert.match(modifySource, /tape_pattern_winner_present/);
assert.doesNotMatch(modifySource, /MODIFY_INK_INVALID_EFFECT_TINT/);
assert.match(schema, /DB_VERSION: number = 59/);
assert.match(schema, /create_ink_effects TEXT NOT NULL DEFAULT '0'/);
assert.match(schema, /ink_effects_tinted_winner_present INTEGER NOT NULL/);
assert.match(model, /inkEffects\?: string/); assert.match(model, /inkEffectPhase\?: number/);
assert.match(clipboard, /inkEffects: stroke\.renderSpec\.inkEffects/);
assert.match(packageSpec, /isUnsignedLongDecimal\(stroke\.renderSpec\.inkEffects\)/);
assert.match(canvasView, /inkEffects: s\.renderSpec\.inkEffects/);
assert.match(canvasView, /inkEffectsTinted: s\.renderSpec\.inkEffectsTinted/);
assert.match(canvasView, /inkEffectPhase: s\.renderSpec\.inkEffectPhase/);

console.log('success|flatbuffer-create-fields-18-19=2|modify-fields-16-18=3|' +
  'v47-v48-defaults=3|uint64-max=1|create-retry-conflict=2|effect-bits=rainbow-glitter-unknown|' +
  'independent-lww=2|site-tiebreak=1|stale=1|hidden=1|phase=1|' +
  'multi-ink-atomic=2|rollback=2|tape-deferred=1|source-wiring=complete');
