import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

const db = new DatabaseSync(':memory:');
db.exec(`PRAGMA foreign_keys=ON;
CREATE TABLE note_meta(id TEXT PRIMARY KEY,structure_revision INTEGER NOT NULL DEFAULT 0);
CREATE TABLE page_info(page_id TEXT PRIMARY KEY,note_id TEXT NOT NULL,page_index INTEGER NOT NULL,
 size INTEGER NOT NULL,template INTEGER NOT NULL,orientation INTEGER NOT NULL,width_mm REAL NOT NULL,
 height_mm REAL NOT NULL,content_revision INTEGER NOT NULL,UNIQUE(note_id,page_index),UNIQUE(note_id,page_id));
CREATE TABLE page_element_snapshot(note_id TEXT,page_id TEXT,element_id TEXT,kind INTEGER,payload BLOB,
 revision INTEGER,element_order INTEGER,PRIMARY KEY(note_id,page_id,element_id,kind),
 FOREIGN KEY(note_id,page_id) REFERENCES page_info(note_id,page_id) ON DELETE CASCADE);
CREATE TABLE search_item(id INTEGER PRIMARY KEY,note_id TEXT,type INTEGER,sub_id TEXT,page_id TEXT,
 folded_text TEXT,rects BLOB,UNIQUE(note_id,type,sub_id),
 FOREIGN KEY(note_id,page_id) REFERENCES page_info(note_id,page_id) ON DELETE CASCADE);
CREATE TABLE search_page_state(note_id TEXT,page_id TEXT,indexed_revision INTEGER,
 PRIMARY KEY(note_id,page_id),FOREIGN KEY(note_id,page_id) REFERENCES page_info(note_id,page_id) ON DELETE CASCADE);
CREATE TABLE original_page_identity(note_id TEXT,seq_timestamp INTEGER,seq_site_id INTEGER,seq_index INTEGER,
 page_id TEXT,visible INTEGER,PRIMARY KEY(note_id,seq_timestamp,seq_site_id,seq_index),UNIQUE(note_id,page_id));
CREATE TABLE original_page_position_group(note_id TEXT,op_timestamp INTEGER,op_site_id INTEGER,
 parent_timestamp INTEGER,parent_site_id INTEGER,parent_index INTEGER,position_count INTEGER,modified_time TEXT,
 PRIMARY KEY(note_id,op_timestamp,op_site_id));
CREATE TABLE original_page_position(note_id TEXT,pos_timestamp INTEGER,pos_site_id INTEGER,pos_index INTEGER,
 page_timestamp INTEGER,page_site_id INTEGER,page_index INTEGER,
 PRIMARY KEY(note_id,pos_timestamp,pos_site_id,pos_index));
CREATE TABLE original_page_position_winner(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,page_index INTEGER,
 winner_timestamp INTEGER,winner_site_id INTEGER,position_index INTEGER,
 PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index));
PRAGMA user_version=23;
CREATE TABLE original_page_visibility_winner(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,page_index INTEGER,
 winner_timestamp INTEGER,winner_site_id INTEGER,deleted INTEGER CHECK(deleted IN(0,1)),
 PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index));
CREATE TABLE original_deleted_page(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,page_index INTEGER,
 page_id TEXT,size INTEGER,template INTEGER,orientation INTEGER,width_mm REAL,height_mm REAL,
 content_revision INTEGER,indexed_revision INTEGER,
 PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index),UNIQUE(note_id,page_id));
CREATE TABLE original_deleted_page_element(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,page_index INTEGER,
 element_id TEXT,kind INTEGER,payload BLOB,revision INTEGER,element_order INTEGER,
 PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index,element_id,kind),
 FOREIGN KEY(note_id,page_timestamp,page_site_id,page_index) REFERENCES original_deleted_page ON DELETE CASCADE);
CREATE TABLE original_deleted_page_search(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,page_index INTEGER,
 type INTEGER,sub_id TEXT,folded_text TEXT,rects BLOB,
 PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index,type,sub_id),
 FOREIGN KEY(note_id,page_timestamp,page_site_id,page_index) REFERENCES original_deleted_page ON DELETE CASCADE);
PRAGMA user_version=24;
INSERT INTO note_meta VALUES('note',0);
INSERT INTO original_page_identity VALUES
 ('note',10,1,0,'A',1),('note',10,1,1,'B',1),('note',10,1,2,'C',1),('note',11,1,0,'D',1);
INSERT INTO original_page_position_group VALUES
 ('note',10,1,NULL,NULL,NULL,3,'10'),('note',11,1,10,1,1,1,'11');
INSERT INTO original_page_position VALUES
 ('note',10,1,0,10,1,0),('note',10,1,1,10,1,1),('note',10,1,2,10,1,2),
 ('note',11,1,0,11,1,0);
INSERT INTO original_page_position_winner VALUES
 ('note',10,1,0,10,1,0),('note',10,1,1,10,1,1),('note',10,1,2,10,1,2),
 ('note',11,1,0,11,1,0);
INSERT INTO page_info VALUES
 ('A','note',0,1,0,0,210,297,0),('B','note',1,2,3,1,220,300,7),
 ('D','note',2,1,0,0,210,297,0),('C','note',3,1,0,0,210,297,0);
INSERT INTO page_element_snapshot VALUES('note','B','ink-b',0,x'010203',7,0);
INSERT INTO search_item VALUES(NULL,'note',3,'ink-b','B','hello',x'0405');
INSERT INTO search_page_state VALUES('note','B',7);`);

const seq = (timestamp,site,index) => ({ timestamp,site,index });
const key = value => `${value.timestamp}:${value.site}:${value.index}`;
const opKey = value => `${value.timestamp}:${value.site}`;
const compareOp = (left,right) => left.timestamp !== right.timestamp ?
  (left.timestamp < right.timestamp ? -1 : 1) : left.site === right.site ? 0 : left.site < right.site ? -1 : 1;
const compareSeq = (left,right) => left.timestamp !== right.timestamp ? left.timestamp-right.timestamp :
  left.site !== right.site ? left.site-right.site : right.index-left.index;

function visibleOrder() {
  const rows = db.prepare(`SELECT g.*,p.pos_index,i.page_id,i.visible,w.winner_timestamp,w.winner_site_id,
    w.position_index,COALESCE(v.deleted,0) deleted FROM original_page_position_group g
    JOIN original_page_position p ON p.note_id=g.note_id AND p.pos_timestamp=g.op_timestamp AND p.pos_site_id=g.op_site_id
    JOIN original_page_identity i ON i.note_id=p.note_id AND i.seq_timestamp=p.page_timestamp
      AND i.seq_site_id=p.page_site_id AND i.seq_index=p.page_index
    JOIN original_page_position_winner w ON w.note_id=p.note_id AND w.page_timestamp=p.page_timestamp
      AND w.page_site_id=p.page_site_id AND w.page_index=p.page_index
    LEFT JOIN original_page_visibility_winner v ON v.note_id=p.note_id AND v.page_timestamp=p.page_timestamp
      AND v.page_site_id=p.page_site_id AND v.page_index=p.page_index
    WHERE g.note_id='note' ORDER BY g.op_timestamp,g.op_site_id,p.pos_index`).all();
  const groups = new Map();
  for (const row of rows) {
    const id = opKey(seq(row.op_timestamp,row.op_site_id,0));
    if (!groups.has(id)) groups.set(id,{ op:seq(row.op_timestamp,row.op_site_id,0),
      parent:row.parent_timestamp===null?null:seq(row.parent_timestamp,row.parent_site_id,row.parent_index),
      count:row.position_count,positions:[] });
    const position = seq(row.op_timestamp,row.op_site_id,row.pos_index);
    groups.get(id).positions.push({ position,pageId:row.page_id,deleted:row.deleted===1,
      active:row.winner_timestamp===position.timestamp&&row.winner_site_id===position.site&&
        row.position_index===position.index });
  }
  const children = new Map();
  for (const group of groups.values()) {
    assert.equal(group.positions.length,group.count);
    const parent = group.parent===null?'ROOT':key(group.parent);
    children.set(parent,[...(children.get(parent)??[]),group]);
  }
  for (const siblings of children.values()) siblings.sort((a,b)=>-compareSeq(a.positions.at(-1).position,b.positions.at(-1).position));
  const result=[],visited=new Set();
  const append = parent => {
    for (const group of children.get(parent)??[]) {
      assert(!visited.has(opKey(group.op))); visited.add(opKey(group.op));
      for (const position of group.positions) {
        if (position.active&&!position.deleted) result.push(position.pageId);
        append(key(position.position));
      }
    }
  };
  append('ROOT'); assert.equal(visited.size,groups.size); return result;
}

const storedOrder = () => db.prepare(`SELECT page_id FROM page_info WHERE note_id='note' ORDER BY page_index`).all().map(r=>r.page_id);
const identityExists = page => db.prepare(`SELECT 1 FROM original_page_identity WHERE note_id='note'
 AND seq_timestamp=? AND seq_site_id=? AND seq_index=? AND visible=1 AND page_id IS NOT NULL`).get(
 page.timestamp,page.site,page.index)!==undefined;
const winner = page => db.prepare(`SELECT winner_timestamp timestamp,winner_site_id site,deleted
 FROM original_page_visibility_winner WHERE note_id='note' AND page_timestamp=? AND page_site_id=? AND page_index=?`).get(
 page.timestamp,page.site,page.index);

function archive(page,failAt) {
  const id = db.prepare(`SELECT page_id FROM original_page_identity WHERE note_id='note' AND seq_timestamp=?
   AND seq_site_id=? AND seq_index=?`).get(page.timestamp,page.site,page.index).page_id;
  db.prepare(`INSERT INTO original_deleted_page SELECT 'note',?,?,?,p.page_id,p.size,p.template,p.orientation,
   p.width_mm,p.height_mm,p.content_revision,s.indexed_revision FROM page_info p LEFT JOIN search_page_state s
   ON s.note_id=p.note_id AND s.page_id=p.page_id WHERE p.note_id='note' AND p.page_id=?`).run(
   page.timestamp,page.site,page.index,id);
  db.prepare(`INSERT INTO original_deleted_page_element SELECT 'note',?,?,?,element_id,kind,payload,revision,element_order
   FROM page_element_snapshot WHERE note_id='note' AND page_id=?`).run(page.timestamp,page.site,page.index,id);
  db.prepare(`INSERT INTO original_deleted_page_search SELECT 'note',?,?,?,type,sub_id,folded_text,rects
   FROM search_item WHERE note_id='note' AND page_id=?`).run(page.timestamp,page.site,page.index,id);
  if (failAt==='archive') throw new Error('injected');
  assert.equal(db.prepare(`DELETE FROM page_info WHERE note_id='note' AND page_id=?`).run(id).changes,1);
}

function restore(page,tempIndex) {
  const archived = db.prepare(`SELECT * FROM original_deleted_page WHERE note_id='note' AND page_timestamp=?
   AND page_site_id=? AND page_index=?`).get(page.timestamp,page.site,page.index);
  assert(archived);
  db.prepare(`INSERT INTO page_info VALUES(?,?,?,?,?,?,?,?,?)`).run(archived.page_id,'note',tempIndex,
   archived.size,archived.template,archived.orientation,archived.width_mm,archived.height_mm,archived.content_revision);
  db.prepare(`INSERT INTO page_element_snapshot SELECT 'note',?,element_id,kind,payload,revision,element_order
   FROM original_deleted_page_element WHERE note_id='note' AND page_timestamp=? AND page_site_id=? AND page_index=?`).run(
   archived.page_id,page.timestamp,page.site,page.index);
  db.prepare(`INSERT INTO search_item SELECT NULL,'note',type,sub_id,?,folded_text,rects
   FROM original_deleted_page_search WHERE note_id='note' AND page_timestamp=? AND page_site_id=? AND page_index=?`).run(
   archived.page_id,page.timestamp,page.site,page.index);
  if (archived.indexed_revision!==null) db.prepare(`INSERT INTO search_page_state VALUES('note',?,?)`).run(
   archived.page_id,archived.indexed_revision);
  db.prepare(`DELETE FROM original_deleted_page WHERE note_id='note' AND page_timestamp=?
   AND page_site_id=? AND page_index=?`).run(page.timestamp,page.site,page.index);
}

function applyVisibility(op,deletes,undeletes,{ entities=0,failAt='' }={}) {
  const unique = values => [...new Map(values.map(value=>[key(value),value])).values()];
  deletes=unique(deletes); undeletes=unique(undeletes);
  if (entities>0||deletes.length+undeletes.length===0) return false;
  if ([...deletes,...undeletes].some(page=>!identityExists(page))) return false;
  if (JSON.stringify(storedOrder())!==JSON.stringify(visibleOrder())) return false;
  db.exec('BEGIN IMMEDIATE');
  try {
    const before=storedOrder();
    const setIndex=db.prepare(`UPDATE page_info SET page_index=? WHERE note_id='note' AND page_id=?`);
    before.forEach((id,index)=>assert.equal(setIndex.run(-(index+1),id).changes,1));
    let restored=0;
    for (const [pages,deleted] of [[deletes,1],[undeletes,0]]) for (const page of pages) {
      const old=winner(page);
      if (old&&compareOp(op,old)<0) continue;
      const wasDeleted=old?.deleted===1;
      if (wasDeleted!==(deleted===1)) {
        if (deleted===1) archive(page,failAt);
        else restore(page,-(before.length+(++restored)));
      }
      db.prepare(`INSERT INTO original_page_visibility_winner VALUES('note',?,?,?,?,?,?)
       ON CONFLICT(note_id,page_timestamp,page_site_id,page_index) DO UPDATE SET
       winner_timestamp=excluded.winner_timestamp,winner_site_id=excluded.winner_site_id,deleted=excluded.deleted`).run(
       page.timestamp,page.site,page.index,op.timestamp,op.site,deleted);
    }
    const after=visibleOrder(),live=storedOrder();
    assert.deepEqual(new Set(live),new Set(after));
    after.forEach((id,index)=>assert.equal(setIndex.run(index,id).changes,1));
    db.prepare(`UPDATE note_meta SET structure_revision=structure_revision+1 WHERE id='note'`).run();
    db.exec('COMMIT'); return true;
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

function addMove(op,page,target=null) {
  db.prepare(`INSERT INTO original_page_position_group VALUES('note',?,?,?,?,?,?,?)`).run(
   op.timestamp,op.site,target?.timestamp??null,target?.site??null,target?.index??null,1,String(op.timestamp));
  db.prepare(`INSERT INTO original_page_position VALUES('note',?,?,?,?,?,?)`).run(
   op.timestamp,op.site,0,page.timestamp,page.site,page.index);
  db.prepare(`UPDATE original_page_position_winner SET winner_timestamp=?,winner_site_id=?,position_index=0
   WHERE note_id='note' AND page_timestamp=? AND page_site_id=? AND page_index=?`).run(
   op.timestamp,op.site,page.timestamp,page.site,page.index);
  const before=storedOrder(),setIndex=db.prepare(`UPDATE page_info SET page_index=? WHERE note_id='note' AND page_id=?`);
  before.forEach((id,index)=>setIndex.run(-(index+1),id)); visibleOrder().forEach((id,index)=>setIndex.run(index,id));
}

function addCreate(page,pageId,parent) {
  assert.deepEqual(storedOrder(),visibleOrder());
  db.prepare(`INSERT INTO original_page_identity VALUES('note',?,?,?,?,1)`).run(
   page.timestamp,page.site,page.index,pageId);
  db.prepare(`INSERT INTO original_page_position_group VALUES('note',?,?,?,?,?,?,?)`).run(
   page.timestamp,page.site,parent.timestamp,parent.site,parent.index,1,String(page.timestamp));
  db.prepare(`INSERT INTO original_page_position VALUES('note',?,?,?,?,?,?)`).run(
   page.timestamp,page.site,page.index,page.timestamp,page.site,page.index);
  db.prepare(`INSERT INTO original_page_position_winner VALUES('note',?,?,?,?,?,?)`).run(
   page.timestamp,page.site,page.index,page.timestamp,page.site,page.index);
  db.prepare(`INSERT INTO page_info VALUES(?,?,?,?,?,?,?,?,?)`).run(pageId,'note',-1,1,0,0,210,297,0);
  visibleOrder().forEach((id,index)=>db.prepare(`UPDATE page_info SET page_index=? WHERE page_id=?`).run(index,id));
}

const A=seq(10,1,0),B=seq(10,1,1),C=seq(10,1,2),D=seq(11,1,0);
assert.equal(db.prepare('PRAGMA user_version').get().user_version,24);
assert.deepEqual(visibleOrder(),['A','B','D','C']);
assert.equal(applyVisibility(seq(20,2,0),[B],[]),true);
assert.deepEqual(visibleOrder(),['A','D','C']);
assert.equal(db.prepare(`SELECT hex(payload) payload FROM original_deleted_page_element`).get().payload,'010203');
assert.equal(applyVisibility(seq(21,2,0),[],[B]),true);
assert.deepEqual(visibleOrder(),['A','B','D','C']);
assert.equal(db.prepare(`SELECT hex(payload) payload FROM page_element_snapshot WHERE page_id='B'`).get().payload,'010203');
assert.equal(db.prepare(`SELECT folded_text FROM search_item WHERE page_id='B'`).get().folded_text,'hello');
assert.equal(db.prepare(`SELECT indexed_revision FROM search_page_state WHERE page_id='B'`).get().indexed_revision,7);
assert.equal(applyVisibility(seq(30,2,0),[B,C],[]),true);
assert.deepEqual(visibleOrder(),['A','D']);
assert.equal(applyVisibility(seq(31,2,0),[B,B],[B,B]),true);
assert.deepEqual(visibleOrder(),['A','B','D']);
assert.equal(applyVisibility(seq(25,9,0),[],[C]),true);
assert.deepEqual(visibleOrder(),['A','B','D']);
assert.equal(applyVisibility(seq(40,2,0),[],[C]),true);
addMove(seq(50,2,0),B);
assert.deepEqual(visibleOrder(),['B','A','D','C']);
assert.equal(applyVisibility(seq(60,2,0),[B],[]),true);
assert.equal(applyVisibility(seq(61,2,0),[],[B]),true);
assert.deepEqual(visibleOrder(),['B','A','D','C']);
assert.equal(applyVisibility(seq(62,2,0),[seq(99,1,0)],[]),false);
assert.equal(applyVisibility(seq(63,2,0),[A],[],{entities:1}),false);
const diverged=storedOrder(),setDiverged=db.prepare(`UPDATE page_info SET page_index=? WHERE note_id='note' AND page_id=?`);
diverged.forEach((id,index)=>setDiverged.run(-(index+1),id));
[...diverged].reverse().forEach((id,index)=>setDiverged.run(index,id));
assert.equal(applyVisibility(seq(63,3,0),[A],[]),false);
diverged.forEach((id,index)=>setDiverged.run(-(index+1),id));
diverged.forEach((id,index)=>setDiverged.run(index,id));
const beforeFailure=JSON.stringify(db.prepare(`SELECT * FROM page_info ORDER BY page_index`).all());
assert.throws(()=>applyVisibility(seq(64,2,0),[A],[],{failAt:'archive'}),/injected/);
assert.equal(JSON.stringify(db.prepare(`SELECT * FROM page_info ORDER BY page_index`).all()),beforeFailure);
assert.equal(db.prepare(`SELECT 1 FROM original_page_visibility_winner WHERE winner_timestamp=64`).get(),undefined);
assert.equal(applyVisibility(seq(70,2,0),[A,B,C,D],[]),true);
assert.deepEqual(visibleOrder(),[]);
assert.deepEqual(storedOrder(),[]);
const E=seq(90,1,0);
addCreate(E,'E',B);
assert.deepEqual(visibleOrder(),['E']);
assert.equal(applyVisibility(seq(100,2,0),[],[A,B,C,D]),true);
assert.deepEqual(visibleOrder(),['B','A','E','D','C']);
assert.equal(db.prepare('PRAGMA foreign_key_check').all().length,0);

console.log('success|v23-v24=1|delete=1|undelete-full=1|batch=1|same-payload=1|deleted-anchor=1|lww-opid=1|move-restore=1|zero-pages=1|create-after-tombstone=1|entity-deferred=1|missing-deferred=1|diverged-deferred=1|rollback=1');
