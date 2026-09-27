// Phase 928 — 叶结构 + zgb/ww9 回归
// 证据：docs/migration/evidence/phase-928-leaf-closure.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const fqa = rd('fqa.java');
ok(fqa.includes('Point(x=') && fqa.includes('y='), 'fqa = Point');
ok(fqa.includes('getFloat(this.I)') && fqa.includes('getFloat(this.I + 4)'),
  'fqa {x@0,y@4}');
ok(fqa.includes('extends xwd'), 'fqa inline struct');

const qed = rd('qed.java');
ok(qed.includes('Size(width=') && qed.includes('height='), 'qed = Size');
// c() reads +4 (height), d() reads +0 (width)
ok(qed.match(/float c\(\)[\s\S]{0,60}getFloat\(this\.I \+ 4\)/), 'qed height@+4');
ok(qed.match(/float d\(\)[\s\S]{0,60}getFloat\(this\.I\)/), 'qed width@+0');

ok(rd('hd1.java').includes('CanvasAnchor(page=') && rd('hd1.java').includes('origin='),
  'hd1 = CanvasAnchor');
ok(rd('my3.java').includes('EntityAnchor(entities='), 'my3 = EntityAnchor');

const zgb = rd('zgb.java');
ok(zgb.includes('ReceiveOpsEvent(ops=') && zgb.includes('expectedAckReply=') &&
   zgb.includes('schemaVersion='), 'zgb = ReceiveOpsEvent server->client batch');
ok(zgb.includes('lv2.V(this)') && zgb.includes('ymf.a(l())'),
  'zgb ops vector + ymf schemaVersion');

ok(rd('ww9.java').includes('STRING((byte) 0)') &&
   rd('ww9.java').includes('BOOLEAN((byte) 1)'), 'ww9 = PDFField valueType');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
