// Phase 936 — 四锚类型字段布局回归
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const hd1 = rd('hd1.java');
ok(hd1.includes('extends xwd'), 'hd1 = inline struct');
ok(hd1.match(/cxc d\(\)[\s\S]{0,80}this\.I\b(?!\s*\+)/), 'CanvasAnchor page:cxc @+0');
ok(hd1.match(/fqa c\(\)[\s\S]{0,80}this\.I \+ 12/), 'origin:fqa @+12');
ok(hd1.includes('CanvasAnchor(page='), 'hd1 = CanvasAnchor');

const lhe = rd('lhe.java');
ok(lhe.match(/qo5 k\(\)[\s\S]{0,80}c\(4\)/), 'TextAnchor textField:qo5 @c(4)');
ok(lhe.match(/qqe j\(\)[\s\S]{0,80}c\(6\)/), 'selection:qqe @c(6)');
ok(lhe.includes('TextAnchor(textField='), 'lhe = TextAnchor');

const cwb = rd('cwb.java');
ok(cwb.includes('extends xwd'), 'cwb = inline struct');
ok(cwb.match(/qo5 c\(\)[\s\S]{0,80}this\.I\b/), 'ReplyAnchor root:qo5 @+0 (8B)');
ok(cwb.includes('ReplyAnchor(root='), 'cwb = ReplyAnchor');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
