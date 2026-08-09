import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

class Builder {
  constructor() { this.bytes=new Uint8Array(1024);this.cursor=4; }
  align(value) { while((this.cursor&(value-1))!==0)this.cursor++; }
  table(offsets,size) { const v=this.cursor,vs=4+offsets.length*2;this.cursor+=vs;this.align(4);
    const t=this.cursor;this.cursor+=size;w16(this.bytes,v,vs);w16(this.bytes,v+2,size);
    offsets.forEach((value,index)=>w16(this.bytes,v+4+index*2,value));w32(this.bytes,t,t-v);return t; }
  pointer(slot,target) { assert(target>slot);w32(this.bytes,slot,target-slot); }
  vector(values) { this.align(4);const v=this.cursor;this.cursor+=4+values.length;
    w32(this.bytes,v,values.length);this.bytes.set(values,v+4);return v; }
  finish(root) { w32(this.bytes,0,root);return this.bytes.slice(0,this.cursor); }
}
class Table {
  constructor(bytes,table) { this.bytes=bytes;this.table=table;this.vtable=table-i32(bytes,table);
    this.vtableSize=u16(bytes,this.vtable);this.objectSize=u16(bytes,this.vtable+2); }
  offset(field) { const e=this.vtable+4+field*2;return e+2<=this.vtable+this.vtableSize?u16(this.bytes,e):0; }
  inline(field,size) { const o=this.offset(field);if(o===0)return null;assert(o+size<=this.objectSize);
    return this.bytes.slice(this.table+o,this.table+o+size); }
  tableField(field) { const o=this.offset(field);if(o===0)return null;const p=this.table+o;
    return new Table(this.bytes,p+u32(this.bytes,p)); }
  vector(field) { const o=this.offset(field);if(o===0)return null;const p=this.table+o;
    const v=p+u32(this.bytes,p),count=u32(this.bytes,v);return this.bytes.slice(v+4,v+4+count); }
}

function createInkFixture(path,tool=0,style=0) {
  const b=new Builder(),root=b.table([4,12,20,0,28,32],36);
  w16(b.bytes,root+4,7);w32(b.bytes,root+8,90);w64(b.bytes,root+12,123n);
  w64(b.bytes,root+20,124n);b.bytes[root+28]=15;
  const fields=[4,16,24,28,36,37,0,40,44,48,0,0,0,0,56,0,0,0,0,0];
  const ink=b.table(fields,64);b.pointer(root+32,ink);
  w16(b.bytes,ink+4,1);w32(b.bytes,ink+8,10);w32(b.bytes,ink+12,2);
  wf32(b.bytes,ink+16,12);wf32(b.bytes,ink+20,34);wf32(b.bytes,ink+24,Math.PI/2);
  wf32(b.bytes,ink+28,2);wf32(b.bytes,ink+32,3);b.bytes[ink+36]=tool;b.bytes[ink+37]=style;
  b.bytes.set([10,20,30,128],ink+40);
  wf32(b.bytes,ink+44,4);w64(b.bytes,ink+56,18446744073709551615n);
  const vector=b.vector(path);b.pointer(ink+48,vector);return b.finish(root);
}

function decodeCreateInkFixture(bytes) {
  const root=new Table(bytes,u32(bytes,0));assert.equal(root.inline(4,1)[0],15);
  const ink=root.tableField(5),page=ink.inline(0,12),origin=ink.inline(1,8),scale=ink.inline(3,8);
  return {page:{site:u16(page,0),timestamp:u32(page,4),index:u32(page,8)},
    origin:[readf32(origin,0),readf32(origin,4)],rotation:readf32(ink.inline(2,4),0),
    scale:[readf32(scale,0),readf32(scale,4)],tool:normalizeEnum(ink.inline(4,1)[0],7),
    style:normalizeEnum(ink.inline(5,1)[0],3),color:[...ink.inline(7,4)],
    width:readf32(ink.inline(8,4),0),z:u64(ink.inline(14,8),0),path:decodePath(ink.vector(9))};
}

function decodeHalf(value) {
  const sign = (value & 0x8000) === 0 ? 1 : -1;
  const exponent = value >>> 10 & 31, fraction = value & 1023;
  if (exponent === 0) return sign * fraction * 2 ** -24;
  if (exponent === 31) return fraction === 0 ? sign * Infinity : NaN;
  return sign * (1 + fraction / 1024) * 2 ** (exponent - 15);
}

function decodePath(bytes) {
  assert(bytes.length >= 3 && bytes[0] >>> 3 === 0);
  const encoding = bytes[0] & 7, count = bytes[1] * 256 + bytes[2];
  assert([0, 1].includes(encoding) && count >= 2 && count <= 65535);
  let offset = 3, moves = 0; const elements = [];
  for (let index = 0; index < count; index++) {
    const type = bytes[offset++]; assert(type >= 0 && type <= 7);
    const pointCount = [0,4].includes(type) ? 3 : [1,5].includes(type) ? 2 : 1;
    const points = [];
    for (let point = 0; point < pointCount; point++) {
      if (encoding === 0) {
        points.push({x:decodeHalf(bytes[offset]*256+bytes[offset+1]),
          y:decodeHalf(bytes[offset+2]*256+bytes[offset+3])}); offset += 4;
      } else {
        const view = new DataView(bytes.buffer,bytes.byteOffset+offset,8);
        points.push({x:view.getFloat32(0,true),y:view.getFloat32(4,true)}); offset += 8;
      }
    }
    const attributed = type <= 3;
    const attributes = attributed ? {
      width:decodeHalf(bytes[offset]*256+bytes[offset+1]),
      force:decodeHalf(bytes[offset+2]*256+bytes[offset+3]),
      altitude:bytes[offset+4]*Math.PI/(2*255),azimuth:bytes[offset+5]*Math.PI*2/256} :
      {width:1,force:-1,altitude:-1,azimuth:-1};
    if (attributed) offset += 6;
    if ([3,7].includes(type)) moves++;
    elements.push({type,points,...attributes,attributed});
  }
  assert.equal(offset, bytes.length); assert.equal(moves, 1);
  assert([3,7].includes(elements[0].type));
  return elements;
}

function pathFixture() {
  const bytes = [1,0,3];
  element(bytes,3,[[1,2]],0x3c00,0x3800,0,0);
  element(bytes,0,[[20,-3],[4,5],[6,7]],0x3800,0x3400,255,64);
  element(bytes,2,[[8,9]],0x3c00,0x3800,128,128);
  return Uint8Array.from(bytes);
}
function element(target,type,points,width,force,altitude,azimuth) {
  target.push(type); for (const [x,y] of points) { f32(target,x); f32(target,y); }
  target.push(width>>>8,width&255,force>>>8,force&255,altitude,azimuth);
}
function f32(target,value) { const bytes=new Uint8Array(new Float32Array([value]).buffer);target.push(...bytes); }

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys=ON; PRAGMA user_version=25;
    CREATE TABLE note_meta(id TEXT PRIMARY KEY);
    CREATE TABLE original_page_identity(note_id TEXT,seq_timestamp INTEGER,seq_site_id INTEGER,
      seq_index INTEGER,page_id TEXT,visible INTEGER,
      PRIMARY KEY(note_id,seq_timestamp,seq_site_id,seq_index));
    CREATE TABLE page_info(note_id TEXT,page_id TEXT,content_revision INTEGER,
      PRIMARY KEY(note_id,page_id));
    CREATE TABLE page_element_snapshot(note_id TEXT,page_id TEXT,element_id TEXT,kind INTEGER,
      payload BLOB,revision INTEGER,element_order INTEGER,
      PRIMARY KEY(note_id,page_id,element_id,kind));
    CREATE TABLE search_page_state(note_id TEXT,page_id TEXT,indexed_revision INTEGER);
    CREATE TABLE search_item(note_id TEXT,page_id TEXT,type INTEGER,sub_id TEXT);
    CREATE TABLE original_deleted_page(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,
      page_index INTEGER,page_id TEXT,content_revision INTEGER,indexed_revision INTEGER,
      PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index));
    CREATE TABLE original_deleted_page_element(note_id TEXT,page_timestamp INTEGER,
      page_site_id INTEGER,page_index INTEGER,element_id TEXT,kind INTEGER,payload BLOB,
      revision INTEGER,element_order INTEGER,
      PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index,element_id,kind));
    CREATE TABLE original_deleted_page_search(note_id TEXT,page_timestamp INTEGER,
      page_site_id INTEGER,page_index INTEGER,type INTEGER,sub_id TEXT);
    INSERT INTO note_meta VALUES('n');
    INSERT INTO original_page_identity VALUES('n',10,1,2,'p',1);`);
  return db;
}

function migrate(db, inject=false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(`CREATE TABLE original_element_z_index(
      note_id TEXT NOT NULL,element_timestamp INTEGER NOT NULL,element_site_id INTEGER NOT NULL,
      page_timestamp INTEGER NOT NULL,page_site_id INTEGER NOT NULL,page_index INTEGER NOT NULL,
      kind INTEGER NOT NULL,z_index TEXT NOT NULL CHECK(length(z_index) BETWEEN 1 AND 20
        AND z_index NOT GLOB '*[^0-9]*' AND (z_index='0' OR substr(z_index,1,1)<>'0')
        AND (length(z_index)<20 OR z_index<='18446744073709551615')),
      PRIMARY KEY(note_id,element_timestamp,element_site_id),
      FOREIGN KEY(note_id,page_timestamp,page_site_id,page_index) REFERENCES
        original_page_identity(note_id,seq_timestamp,seq_site_id,seq_index) ON DELETE CASCADE)`);
    db.exec(`CREATE INDEX idx_original_element_page_z ON original_element_z_index(
      note_id,page_timestamp,page_site_id,page_index,length(z_index),z_index,
      element_timestamp,element_site_id)`);
    if (inject) throw new Error('injected');
    db.exec('PRAGMA user_version=26; COMMIT');
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

function compare(left,right) {
  if (left.z_index.length !== right.z_index.length) return left.z_index.length-right.z_index.length;
  if (left.z_index !== right.z_index) return left.z_index < right.z_index ? -1 : 1;
  return left.element_timestamp-right.element_timestamp || left.element_site_id-right.element_site_id;
}

function apply(db,{timestamp,site,z,archived=false,fail=false}) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const table = archived ? 'original_deleted_page_element' : 'page_element_snapshot';
    const where = archived ? "note_id='n' AND page_timestamp=10 AND page_site_id=1 AND page_index=2" :
      "note_id='n' AND page_id='p'";
    const existing = db.prepare(`SELECT element_id,kind FROM ${table} WHERE ${where}`).all();
    const tracked = db.prepare(`SELECT element_timestamp,element_site_id,kind,z_index
      FROM original_element_z_index WHERE note_id='n' AND page_timestamp=10
      AND page_site_id=1 AND page_index=2`).all();
    const keys = new Set(tracked.map(row=>`${row.kind}:op:${row.element_timestamp.toString(16)}:${row.element_site_id.toString(16)}`));
    if (!existing.every(row=>keys.has(`${row.kind}:${row.element_id}`)) || existing.length!==tracked.length)
      throw new Error('diverged');
    db.prepare(`INSERT INTO original_element_z_index VALUES('n',?,?,10,1,2,1,?)`).run(timestamp,site,z);
    tracked.push({element_timestamp:timestamp,element_site_id:site,kind:1,z_index:z});
    tracked.sort(compare);
    const id=`op:${timestamp.toString(16)}:${site.toString(16)}`;
    const order=tracked.findIndex(row=>row.element_timestamp===timestamp&&row.element_site_id===site);
    if (archived) db.prepare(`INSERT INTO original_deleted_page_element VALUES
      ('n',10,1,2,?,1,x'7b7d',1,?)`).run(id,order);
    else db.prepare(`INSERT INTO page_element_snapshot VALUES('n','p',?,1,x'7b7d',1,?)`).run(id,order);
    for (let index=0;index<tracked.length;index++) {
      const row=tracked[index], elementId=`op:${row.element_timestamp.toString(16)}:${row.element_site_id.toString(16)}`;
      db.prepare(`UPDATE ${table} SET element_order=? WHERE ${where} AND element_id=? AND kind=1`).run(index,elementId);
    }
    if (fail) throw new Error('injected apply');
    if (archived) {
      db.exec(`UPDATE original_deleted_page SET content_revision=content_revision+1,indexed_revision=NULL
        WHERE note_id='n' AND page_timestamp=10 AND page_site_id=1 AND page_index=2;
        DELETE FROM original_deleted_page_search WHERE note_id='n' AND page_timestamp=10
          AND page_site_id=1 AND page_index=2 AND type=3;`);
    } else {
      db.exec(`UPDATE page_info SET content_revision=content_revision+1 WHERE note_id='n' AND page_id='p';
        DELETE FROM search_page_state WHERE note_id='n' AND page_id='p';
        DELETE FROM search_item WHERE note_id='n' AND page_id='p' AND type=3;`);
    }
    db.exec('COMMIT');
  } catch(error) { db.exec('ROLLBACK'); throw error; }
}

const decodedFixture=decodeCreateInkFixture(createInkFixture(pathFixture()));
assert.deepEqual(decodedFixture.page,{site:1,timestamp:10,index:2});
assert.deepEqual(decodedFixture.origin,[12,34]);assert.deepEqual(decodedFixture.scale,[2,3]);
assert(Math.abs(decodedFixture.rotation-Math.PI/2)<1e-7);assert.deepEqual(decodedFixture.color,[10,20,30,128]);
assert.equal(decodedFixture.width,4);assert.equal(decodedFixture.z,18446744073709551615n);
const unknownEnums=decodeCreateInkFixture(createInkFixture(pathFixture(),255,255));
assert.equal(unknownEnums.tool,0);assert.equal(unknownEnums.style,0);
const decoded=decodedFixture.path;
assert.equal(decoded.length,3);assert.equal(decoded[1].points[2].x,6);
assert.equal(decoded[1].width,0.5);assert.equal(decoded[1].force,0.25);
assert(Math.abs(decoded[1].altitude-Math.PI/2)<1e-12);
assert(Math.abs(decoded[1].azimuth-Math.PI/2)<1e-12);
const localBounds=controlHullBounds(decoded);
assert.deepEqual(localBounds,{left:1,top:-3,right:20,bottom:9});
const worldBounds=transformedExpandedBounds(localBounds,decodedFixture.width,
  originalInkTransform(...decodedFixture.origin,decodedFixture.rotation,...decodedFixture.scale));
assert(Math.abs(worldBounds.left+39)<1e-5);assert(Math.abs(worldBounds.top-20)<1e-5);
assert(Math.abs(worldBounds.right-45)<1e-5);assert(Math.abs(worldBounds.bottom-90)<1e-5);
const halfPath=decodePath(Uint8Array.from([0,0,2,
  3,0x3c,0,0x40,0,0x3c,0,0x38,0,0,0,
  2,0x42,0,0x44,0,0x3c,0,0x38,0,255,64]));
assert.deepEqual(halfPath.map(value=>value.points.at(-1)),[{x:1,y:2},{x:3,y:4}]);

const db=database();migrate(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version,26);
db.exec(`INSERT INTO page_info VALUES('n','p',0);
  INSERT INTO search_page_state VALUES('n','p',0);
  INSERT INTO search_item VALUES('n','p',3,'old');`);
apply(db,{timestamp:20,site:2,z:'18446744073709551615'});
apply(db,{timestamp:21,site:1,z:'9'});
assert.deepEqual(db.prepare(`SELECT element_id FROM page_element_snapshot ORDER BY element_order`).all()
  .map(row=>row.element_id),['op:15:1','op:14:2']);
assert.equal(db.prepare(`SELECT content_revision FROM page_info`).get().content_revision,2);
assert.equal(db.prepare(`SELECT count(*) count FROM search_item`).get().count,0);

db.exec(`INSERT INTO original_deleted_page VALUES('n',10,1,2,'p',2,2);
  INSERT INTO original_deleted_page_element SELECT note_id,10,1,2,element_id,kind,payload,revision,
    element_order FROM page_element_snapshot;
  DELETE FROM page_element_snapshot; DELETE FROM page_info;
  INSERT INTO original_deleted_page_search VALUES('n',10,1,2,3,'old');`);
apply(db,{timestamp:22,site:1,z:'10',archived:true});
assert.deepEqual(db.prepare(`SELECT element_id FROM original_deleted_page_element ORDER BY element_order`).all()
  .map(row=>row.element_id),['op:15:1','op:16:1','op:14:2']);
assert.equal(db.prepare(`SELECT indexed_revision FROM original_deleted_page`).get().indexed_revision,null);

const before=db.prepare(`SELECT count(*) count FROM original_element_z_index`).get().count;
assert.throws(()=>apply(db,{timestamp:23,site:1,z:'11',archived:true,fail:true}),/injected apply/);
assert.equal(db.prepare(`SELECT count(*) count FROM original_element_z_index`).get().count,before);
db.exec(`INSERT INTO original_deleted_page_element VALUES('n',10,1,2,'local',1,x'7b7d',3,3)`);
assert.throws(()=>apply(db,{timestamp:24,site:1,z:'12',archived:true}),/diverged/);

const failed=database();assert.throws(()=>migrate(failed,true),/injected/);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version,25);
assert.equal(failed.prepare(`SELECT count(*) count FROM sqlite_master
  WHERE name='original_element_z_index'`).get().count,0);
assert.throws(()=>db.exec(`INSERT INTO original_element_z_index VALUES
  ('n',99,1,10,1,2,1,'18446744073709551616')`));

console.log('success|flatbuffer-dm2=1|path-bits16=1|path-bits32=1|attributed=1|cubic-line=1|transform=1|original-bounds=1|rgba=1|uint64-z=1|v25-v26=1|live-order=1|search-invalidated=1|archive-apply=1|rollback=1|divergence-gate=1|uint64-check=1');

function controlHullBounds(elements){
  const points=elements.flatMap(element=>element.points);
  return {left:Math.min(...points.map(point=>point.x)),top:Math.min(...points.map(point=>point.y)),
    right:Math.max(...points.map(point=>point.x)),bottom:Math.max(...points.map(point=>point.y))};
}
function originalInkTransform(originX,originY,rotation,scaleX,scaleY){
  const cos=Math.cos(rotation),sin=Math.sin(rotation);
  return [cos*scaleX,-sin*scaleY,originX,sin*scaleX,cos*scaleY,originY,0,0,1];
}
function transformedExpandedBounds(bounds,width,transform){
  const padding=width*2,corners=[{x:bounds.left-padding,y:bounds.top-padding},
    {x:bounds.right+padding,y:bounds.top-padding},{x:bounds.right+padding,y:bounds.bottom+padding},
    {x:bounds.left-padding,y:bounds.bottom+padding}];
  const transformed=corners.map(point=>({x:transform[0]*point.x+transform[1]*point.y+transform[2],
    y:transform[3]*point.x+transform[4]*point.y+transform[5]}));
  return {left:Math.min(...transformed.map(point=>point.x)),top:Math.min(...transformed.map(point=>point.y)),
    right:Math.max(...transformed.map(point=>point.x)),bottom:Math.max(...transformed.map(point=>point.y))};
}
function normalizeEnum(value,maximum){return value>=0&&value<=maximum?value:0;}

function u16(bytes,offset){return bytes[offset]+bytes[offset+1]*256;}
function u32(bytes,offset){return bytes[offset]+bytes[offset+1]*256+bytes[offset+2]*65536+bytes[offset+3]*16777216;}
function i32(bytes,offset){const value=u32(bytes,offset);return value>=2147483648?value-4294967296:value;}
function u64(bytes,offset){let value=0n;for(let i=7;i>=0;i--)value=value*256n+BigInt(bytes[offset+i]);return value;}
function readf32(bytes,offset){return new DataView(bytes.buffer,bytes.byteOffset+offset,4).getFloat32(0,true);}
function w16(bytes,offset,value){bytes[offset]=value;bytes[offset+1]=value>>>8;}
function w32(bytes,offset,value){bytes[offset]=value;bytes[offset+1]=value>>>8;bytes[offset+2]=value>>>16;bytes[offset+3]=value>>>24;}
function w64(bytes,offset,value){for(let i=0;i<8;i++){bytes[offset+i]=Number(value&255n);value>>=8n;}}
function wf32(bytes,offset,value){new DataView(bytes.buffer,offset,4).setFloat32(0,value,true);}
