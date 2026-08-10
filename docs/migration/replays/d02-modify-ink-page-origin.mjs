import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

class Builder {
  constructor() { this.bytes = new Uint8Array(1024); this.cursor = 4; }
  align(value) { while ((this.cursor & (value - 1)) !== 0) this.cursor++; }
  table(offsets, size) {
    const vtable = this.cursor, vtableSize = 4 + offsets.length * 2;
    this.cursor += vtableSize; this.align(4); const table = this.cursor; this.cursor += size;
    w16(this.bytes, vtable, vtableSize); w16(this.bytes, vtable + 2, size);
    offsets.forEach((value, index) => w16(this.bytes, vtable + 4 + index * 2, value));
    w32(this.bytes, table, table - vtable); return table;
  }
  pointer(slot, target) { assert(target > slot); w32(this.bytes, slot, target - slot); }
  identities(values) {
    this.align(4); const vector = this.cursor; this.cursor += 4 + values.length * 8;
    w32(this.bytes, vector, values.length);
    values.forEach((value, index) => {
      w16(this.bytes, vector + 4 + index * 8, value.site);
      w32(this.bytes, vector + 8 + index * 8, value.timestamp);
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
    const offset = this.offset(field); if (!offset) return null;
    const pointer = this.table + offset; return new Table(this.bytes, pointer + u32(this.bytes, pointer));
  }
  identities(field) {
    const pointer = this.table + this.offset(field), vector = pointer + u32(this.bytes, pointer);
    const result = [], count = u32(this.bytes, vector);
    for (let index = 0; index < count; index++) {
      const item = vector + 4 + index * 8;
      result.push({ timestamp: u32(this.bytes, item + 4), site: u16(this.bytes, item) });
    }
    return result;
  }
}

function fixture(targets, page, origin, partial = false) {
  const builder = new Builder(), root = builder.table([4, 12, 20, 0, 28, 32], 36);
  w16(builder.bytes, root + 4, 7); w32(builder.bytes, root + 8, 5);
  w64(builder.bytes, root + 12, 1n); w64(builder.bytes, root + 20, 2n);
  builder.bytes[root + 28] = 17;
  const modify = builder.table([4, 8, partial ? 0 : 20, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 28);
  builder.pointer(root + 32, modify);
  w16(builder.bytes, modify + 8, page.site); w32(builder.bytes, modify + 12, page.timestamp);
  w32(builder.bytes, modify + 16, page.index);
  if (!partial) { wf32(builder.bytes, modify + 20, origin.x); wf32(builder.bytes, modify + 24, origin.y); }
  builder.pointer(modify + 4, builder.identities(targets));
  return builder.finish(root);
}

function decode(bytes) {
  const root = new Table(bytes, u32(bytes, 0)); assert.equal(bytes[root.table + root.offset(4)], 17);
  const table = root.nested(5), pageOffset = table.offset(1), originOffset = table.offset(2);
  let pageOrigin = null;
  if (pageOffset && originOffset) {
    pageOrigin = {
      page: { site: u16(bytes, table.table + pageOffset),
        timestamp: u32(bytes, table.table + pageOffset + 4),
        index: u32(bytes, table.table + pageOffset + 8) },
      x: f32(bytes, table.table + originOffset), y: f32(bytes, table.table + originOffset + 4),
    };
  }
  return { targets: table.identities(0), pageOrigin };
}

const pages = {
  p1: { timestamp: 10, site: 1, index: 0 },
  p2: { timestamp: 11, site: 1, index: 0 },
  p3: { timestamp: 12, site: 1, index: 0 },
};
const inks = [{ timestamp: 20, site: 2 }, { timestamp: 21, site: 3 }];

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA user_version=30;
    CREATE TABLE page_identity(timestamp INTEGER,site INTEGER,idx INTEGER,page_id TEXT,archived INTEGER,
      PRIMARY KEY(timestamp,site,idx));
    CREATE TABLE page_state(page_id TEXT PRIMARY KEY,revision INTEGER);
    CREATE TABLE archive_state(page_id TEXT PRIMARY KEY,timestamp INTEGER,site INTEGER,idx INTEGER,revision INTEGER);
    CREATE TABLE element(note_id TEXT,page_id TEXT,element_id TEXT,kind INTEGER,payload TEXT,revision INTEGER,
      element_order INTEGER,PRIMARY KEY(note_id,page_id,element_id,kind));
    CREATE TABLE archive_element(note_id TEXT,page_id TEXT,element_id TEXT,kind INTEGER,payload TEXT,
      revision INTEGER,element_order INTEGER,PRIMARY KEY(note_id,page_id,element_id,kind));
    CREATE TABLE z_state(note_id TEXT,element_timestamp INTEGER,element_site INTEGER,page_timestamp INTEGER,
      page_site INTEGER,page_index INTEGER,kind INTEGER,z_index INTEGER,
      PRIMARY KEY(note_id,element_timestamp,element_site));
    CREATE TABLE ink_state(note_id TEXT,ink_timestamp INTEGER,ink_site INTEGER,
      create_origin_x REAL,create_origin_y REAL,create_rotation REAL,create_scale_x REAL,create_scale_y REAL,
      rotation_value REAL,rotation_winner_present INTEGER,scale_x_value REAL,scale_y_value REAL,
      scale_winner_present INTEGER,PRIMARY KEY(note_id,ink_timestamp,ink_site));
    CREATE TABLE create_state(ink_timestamp INTEGER,ink_site INTEGER,page_timestamp INTEGER,page_site INTEGER,
      page_index INTEGER,origin_x REAL,origin_y REAL,PRIMARY KEY(ink_timestamp,ink_site));
    CREATE TABLE invalidation(page_id TEXT);
    CREATE TABLE operation_log(id INTEGER PRIMARY KEY);
    INSERT INTO page_identity VALUES(10,1,0,'p1',0),(11,1,0,'p2',0),(12,1,0,'p3',1);
    INSERT INTO page_state VALUES('p1',1),('p2',5);
    INSERT INTO archive_state VALUES('p3',12,1,0,8);
    INSERT INTO z_state VALUES
      ('n',20,2,10,1,0,1,10),('n',30,1,10,1,0,1,30),
      ('n',31,1,11,1,0,1,5),('n',32,1,11,1,0,1,20),
      ('n',21,3,12,1,0,1,12),('n',33,1,12,1,0,1,15);
    INSERT INTO ink_state VALUES('n',20,2,10,20,0.25,1.5,0.5,0.75,1,-2,3,1);
    INSERT INTO ink_state VALUES('n',21,3,-4,6,-0.5,2,3,NULL,0,NULL,NULL,0);
    INSERT INTO create_state VALUES(20,2,10,1,0,10,20),(21,3,12,1,0,-4,6);
    INSERT INTO element VALUES
      ('n','p1','20:2',1,'${JSON.stringify(matrix(10,20,0.75,-2,3))}',1,0),
      ('n','p1','30:1',1,'stationary-30',1,1),
      ('n','p2','31:1',1,'stationary-31',5,0),
      ('n','p2','32:1',1,'stationary-32',5,1);
    INSERT INTO archive_element VALUES
      ('n','p3','21:3',1,'${JSON.stringify(matrix(-4,6,-0.5,2,3))}',8,0),
      ('n','p3','33:1',1,'stationary-33',8,1);`);
  return db;
}

function migrate(db, inject = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(`ALTER TABLE ink_state ADD COLUMN create_page_timestamp INTEGER;
      ALTER TABLE ink_state ADD COLUMN create_page_site_id INTEGER;
      ALTER TABLE ink_state ADD COLUMN create_page_index INTEGER;
      ALTER TABLE ink_state ADD COLUMN page_origin_page_timestamp INTEGER;
      ALTER TABLE ink_state ADD COLUMN page_origin_page_site_id INTEGER;
      ALTER TABLE ink_state ADD COLUMN page_origin_page_index INTEGER;
      ALTER TABLE ink_state ADD COLUMN page_origin_x REAL;
      ALTER TABLE ink_state ADD COLUMN page_origin_y REAL;
      ALTER TABLE ink_state ADD COLUMN page_origin_winner_timestamp INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE ink_state ADD COLUMN page_origin_winner_site_id INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE ink_state ADD COLUMN page_origin_winner_present INTEGER NOT NULL DEFAULT 0;`);
    if (inject) throw new Error('injected migration');
    db.exec('PRAGMA user_version=31; COMMIT');
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

function apply(db, timestamp, site, raw, inject = false) {
  const payload = decode(raw); if (!payload.pageOrigin) return 'NO_OP';
  db.exec('BEGIN IMMEDIATE');
  try {
    const plans = [], pageRows = new Map();
    for (const ink of payload.targets) {
      const state = db.prepare(`SELECT * FROM ink_state WHERE note_id='n' AND ink_timestamp=? AND ink_site=?`)
        .get(ink.timestamp, ink.site);
      const create = db.prepare(`SELECT * FROM create_state WHERE ink_timestamp=? AND ink_site=?`)
        .get(ink.timestamp, ink.site);
      const z = db.prepare(`SELECT * FROM z_state WHERE note_id='n' AND element_timestamp=? AND element_site=?`)
        .get(ink.timestamp, ink.site);
      if (!state || !create || !z) { db.exec('ROLLBACK'); return 'MISSING'; }
      if (state.page_origin_winner_present && !newer(timestamp, site,
        state.page_origin_winner_timestamp, state.page_origin_winner_site_id)) continue;
      const source = resolvePage(db, z.page_timestamp, z.page_site, z.page_index);
      const destination = resolvePage(db, payload.pageOrigin.page.timestamp,
        payload.pageOrigin.page.site, payload.pageOrigin.page.index);
      if (!source || !destination) { db.exec('ROLLBACK'); return 'PAGE_MISSING'; }
      const oldPage = state.page_origin_winner_present ? {
        timestamp: state.page_origin_page_timestamp, site: state.page_origin_page_site_id,
        index: state.page_origin_page_index } :
        { timestamp: create.page_timestamp, site: create.page_site, index: create.page_index };
      if (!samePage(oldPage, { timestamp: z.page_timestamp, site: z.page_site, index: z.page_index })) {
        db.exec('ROLLBACK'); return 'DIVERGED';
      }
      const oldOrigin = state.page_origin_winner_present ?
        { x: state.page_origin_x, y: state.page_origin_y } : { x: create.origin_x, y: create.origin_y };
      const rotation = state.rotation_winner_present && state.rotation_value !== null ?
        state.rotation_value : state.create_rotation;
      const scale = state.scale_winner_present && state.scale_x_value !== null ?
        { x: state.scale_x_value, y: state.scale_y_value } :
        { x: state.create_scale_x, y: state.create_scale_y };
      const table = source.archived ? 'archive_element' : 'element';
      const row = db.prepare(`SELECT * FROM ${table} WHERE note_id='n' AND page_id=? AND element_id=? AND kind=1`)
        .get(source.page_id, `${ink.timestamp}:${ink.site}`);
      if (!row || row.payload !== JSON.stringify(matrix(oldOrigin.x,oldOrigin.y,rotation,scale.x,scale.y))) {
        db.exec('ROLLBACK'); return 'DIVERGED';
      }
      plans.push({ ink, state, create, z, source, destination, row, rotation, scale });
    }
    for (const plan of plans) {
      if (!loadPageRows(db, plan.source, pageRows) || !loadPageRows(db, plan.destination, pageRows)) {
        db.exec('ROLLBACK'); return 'ORDER_DIVERGED';
      }
      if (!samePage(plan.source, plan.destination)) {
        const sourceRows = pageRows.get(plan.source.page_id), destinationRows = pageRows.get(plan.destination.page_id);
        const index = sourceRows.findIndex(row => row.timestamp === plan.ink.timestamp && row.site === plan.ink.site);
        if (index < 0) { db.exec('ROLLBACK'); return 'ORDER_DIVERGED'; }
        destinationRows.push(sourceRows.splice(index, 1)[0]);
        sourceRows.sort(compareRows); destinationRows.sort(compareRows);
      }
    }
    const affected = new Map();
    for (const plan of plans) {
      const id = `${plan.ink.timestamp}:${plan.ink.site}`;
      const nextPayload = JSON.stringify(matrix(payload.pageOrigin.x,payload.pageOrigin.y,
        plan.rotation,plan.scale.x,plan.scale.y));
      if (samePage(plan.source, plan.destination)) {
        const table = plan.source.archived ? 'archive_element' : 'element';
        db.prepare(`UPDATE ${table} SET payload=?,revision=? WHERE note_id='n' AND page_id=? AND element_id=? AND kind=1`)
          .run(nextPayload, plan.source.revision + 1, plan.source.page_id, id);
      } else {
        const sourceTable = plan.source.archived ? 'archive_element' : 'element';
        const destinationTable = plan.destination.archived ? 'archive_element' : 'element';
        db.prepare(`DELETE FROM ${sourceTable} WHERE note_id='n' AND page_id=? AND element_id=? AND kind=1`)
          .run(plan.source.page_id, id);
        const order = pageRows.get(plan.destination.page_id)
          .findIndex(row => row.timestamp === plan.ink.timestamp && row.site === plan.ink.site);
        db.prepare(`INSERT INTO ${destinationTable} VALUES('n',?, ?,1,?,?,?)`)
          .run(plan.destination.page_id,id,nextPayload,plan.destination.revision + 1,order);
        db.prepare(`UPDATE z_state SET page_timestamp=?,page_site=?,page_index=?
          WHERE note_id='n' AND element_timestamp=? AND element_site=?`)
          .run(plan.destination.timestamp,plan.destination.site,plan.destination.index,
            plan.ink.timestamp,plan.ink.site);
      }
      db.prepare(`UPDATE ink_state SET create_page_timestamp=?,create_page_site_id=?,create_page_index=?,
        page_origin_page_timestamp=?,page_origin_page_site_id=?,page_origin_page_index=?,
        page_origin_x=?,page_origin_y=?,page_origin_winner_timestamp=?,page_origin_winner_site_id=?,
        page_origin_winner_present=1 WHERE note_id='n' AND ink_timestamp=? AND ink_site=?`)
        .run(plan.create.page_timestamp,plan.create.page_site,plan.create.page_index,
          payload.pageOrigin.page.timestamp,payload.pageOrigin.page.site,payload.pageOrigin.page.index,
          payload.pageOrigin.x,payload.pageOrigin.y,timestamp,site,plan.ink.timestamp,plan.ink.site);
      affected.set(plan.source.page_id,plan.source); affected.set(plan.destination.page_id,plan.destination);
    }
    for (const [pageId, rows] of pageRows) {
      const page = resolvePageId(db,pageId), table = page.archived ? 'archive_element' : 'element';
      rows.forEach((row,index) => db.prepare(`UPDATE ${table} SET element_order=?
        WHERE note_id='n' AND page_id=? AND element_id=? AND kind=?`)
        .run(index,pageId,`${row.timestamp}:${row.site}`,row.kind));
    }
    if (inject) throw new Error('injected apply');
    for (const page of affected.values()) {
      const stateTable = page.archived ? 'archive_state' : 'page_state';
      db.prepare(`UPDATE ${stateTable} SET revision=revision+1 WHERE page_id=?`).run(page.page_id);
      db.prepare('INSERT INTO invalidation VALUES(?)').run(page.page_id);
    }
    db.exec('COMMIT'); return plans.length ? 'APPLIED' : 'STALE';
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

assert.equal(decode(fixture(inks, pages.p2, { x: 40, y: 50 })).pageOrigin.x, 40);
assert.equal(decode(fixture(inks, pages.p2, { x: 40, y: 50 }, true)).pageOrigin, null);
const db = database(); migrate(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version,31);
assert.equal(apply(db,5,1,fixture([inks[0]],pages.p2,{x:100,y:200})),'APPLIED');
assert.deepEqual(db.prepare(`SELECT element_id FROM element WHERE page_id='p2' ORDER BY element_order`)
  .all().map(row=>row.element_id),['31:1','20:2','32:1']);
assert.equal(db.prepare(`SELECT z_index FROM z_state WHERE element_timestamp=20`).get().z_index,10);
assert.equal(db.prepare(`SELECT payload FROM element WHERE page_id='p2' AND element_id='20:2'`).get().payload,
  JSON.stringify(matrix(100,200,0.75,-2,3)));
assert.equal(apply(db,4,9,fixture([inks[0]],pages.p1,{x:0,y:0})),'STALE');
assert.equal(apply(db,6,1,fixture([inks[0]],pages.p2,{x:110,y:210})),'APPLIED');
assert.equal(db.prepare(`SELECT revision FROM page_state WHERE page_id='p2'`).get().revision,7);
assert.equal(apply(db,7,1,fixture([inks[1]],pages.p1,{x:8,y:9})),'APPLIED');
assert.equal(db.prepare(`SELECT count(*) count FROM archive_element WHERE element_id='21:3'`).get().count,0);
assert.equal(db.prepare(`SELECT count(*) count FROM element WHERE page_id='p1' AND element_id='21:3'`).get().count,1);
assert.equal(apply(db,8,1,fixture([inks[0]],pages.p3,{x:-10,y:-20})),'APPLIED');
assert.equal(db.prepare(`SELECT count(*) count FROM archive_element WHERE page_id='p3' AND element_id='20:2'`).get().count,1);
const before = db.prepare(`SELECT page_origin_winner_timestamp value FROM ink_state WHERE ink_timestamp=20`).get().value;
db.exec(`UPDATE element SET payload='bad' WHERE page_id='p1' AND element_id='21:3'`);
assert.equal(apply(db,9,1,fixture(inks,pages.p2,{x:1,y:2})),'DIVERGED');
assert.equal(db.prepare(`SELECT page_origin_winner_timestamp value FROM ink_state WHERE ink_timestamp=20`).get().value,before);
db.exec(`UPDATE element SET payload='${JSON.stringify(matrix(8,9,-0.5,2,3))}' WHERE page_id='p1' AND element_id='21:3'`);
assert.throws(()=>apply(db,10,1,fixture(inks,pages.p2,{x:3,y:4}),true),/injected apply/);
assert.equal(db.prepare(`SELECT page_origin_winner_timestamp value FROM ink_state WHERE ink_timestamp=20`).get().value,before);
assert.equal(db.prepare('SELECT count(*) count FROM operation_log').get().count,0);
const missing=database();migrate(missing);
assert.equal(apply(missing,5,1,fixture([inks[0]],{timestamp:99,site:1,index:0},{x:1,y:2})),'PAGE_MISSING');
const orderBad=database();migrate(orderBad);
orderBad.exec(`INSERT INTO element VALUES('n','p2','local',1,'local',5,2)`);
assert.equal(apply(orderBad,5,1,fixture([inks[0]],pages.p2,{x:1,y:2})),'ORDER_DIVERGED');
assert.equal(orderBad.prepare(`SELECT page_origin_winner_present value FROM ink_state
  WHERE ink_timestamp=20`).get().value,0);
const failed=database(); assert.throws(()=>migrate(failed,true),/injected migration/);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version,30);

console.log('success|flatbuffer-page-origin=1|partial-pair-ignored=1|v30-v31=1|' +
  'lower-first-wins=1|live-live=1|same-page-origin=1|archive-live=1|live-archive=1|' +
  'z-order-preserved=1|transform-registers-preserved=2|pages-revised=2|' +
  'missing-destination=1|order-divergence=1|multi-ink-atomic=2|rollback=1|no-local-log=1');

function resolvePage(db,timestamp,site,index) {
  const row=db.prepare(`SELECT * FROM page_identity WHERE timestamp=? AND site=? AND idx=?`)
    .get(timestamp,site,index); if(!row)return null;
  const state=row.archived?db.prepare('SELECT revision FROM archive_state WHERE page_id=?').get(row.page_id):
    db.prepare('SELECT revision FROM page_state WHERE page_id=?').get(row.page_id);
  return state?{...row,timestamp,site,index,revision:state.revision}:null;
}
function resolvePageId(db,pageId){const row=db.prepare('SELECT * FROM page_identity WHERE page_id=?').get(pageId);
  return resolvePage(db,row.timestamp,row.site,row.idx);}
function loadPageRows(db,page,map){if(map.has(page.page_id))return true;
  const table=page.archived?'archive_element':'element';
  const stored=db.prepare(`SELECT element_id,kind FROM ${table} WHERE note_id='n' AND page_id=?`).all(page.page_id);
  const tracked=db.prepare(`SELECT element_timestamp timestamp,element_site site,kind,z_index z FROM z_state
    WHERE note_id='n' AND page_timestamp=? AND page_site=? AND page_index=?`).all(page.timestamp,page.site,page.index);
  if(stored.length!==tracked.length||stored.some(row=>!tracked.some(z=>row.element_id===`${z.timestamp}:${z.site}`&&row.kind===z.kind)))return false;
  tracked.sort(compareRows);map.set(page.page_id,tracked);return true;}
function compareRows(a,b){return a.z-b.z||a.timestamp-b.timestamp||a.site-b.site;}
function samePage(a,b){return a.timestamp===b.timestamp&&a.site===b.site&&a.index===b.index;}
function newer(timestamp,site,oldTimestamp,oldSite){return timestamp>oldTimestamp||(timestamp===oldTimestamp&&site>oldSite);}
function matrix(x,y,r,sx,sy){const c=Math.cos(r),s=Math.sin(r);return[c*sx,-s*sy,x,s*sx,c*sy,y,0,0,1];}
function f32(bytes,offset){return new DataView(bytes.buffer,bytes.byteOffset+offset,4).getFloat32(0,true);}
function u16(bytes,offset){return bytes[offset]+bytes[offset+1]*256;}
function u32(bytes,offset){return bytes[offset]+bytes[offset+1]*256+bytes[offset+2]*65536+bytes[offset+3]*16777216;}
function i32(bytes,offset){const value=u32(bytes,offset);return value>=2147483648?value-4294967296:value;}
function w16(bytes,offset,value){bytes[offset]=value;bytes[offset+1]=value>>>8;}
function w32(bytes,offset,value){bytes[offset]=value;bytes[offset+1]=value>>>8;bytes[offset+2]=value>>>16;bytes[offset+3]=value>>>24;}
function w64(bytes,offset,value){for(let index=0;index<8;index++){bytes[offset+index]=Number(value&255n);value>>=8n;}}
function wf32(bytes,offset,value){new DataView(bytes.buffer,offset,4).setFloat32(0,value,true);}
