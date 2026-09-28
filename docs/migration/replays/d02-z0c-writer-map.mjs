// Phase 962 — z0c 匿名写器族：15 结构 + 23 表写器函数映射
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const z0c = readFileSync(`${ROOT}/z0c.java`, 'utf8');
const yec = readFileSync(`${ROOT}/yec.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// z0c = synthetic Function0 with variant tag
ok(/public final \/\* synthetic \*\/ class z0c implements Function0/.test(z0c), 'z0c = synthetic Function0');
ok(/switch \(this\.I\)/.test(z0c), 'z0c.invoke: switch(this.I) variant');
ok(/mx7 mx7Var = new mx7\(\)/.test(z0c), 'z0c case21 = mx7 struct registry');
ok(/mx7Var\.put\(npbVar\.b\(/.test(z0c), 'struct keys = npb.b(KClass)');

// yec = merged wx4 for structs
ok(/class yec implements wx4/.test(yec) && /switch \(this\.I\)/.test(yec), 'yec = merged wx4 switch');

// 15 struct writer functions
const structWriters = [
  ['vfj.d((xq3)', 'xq3 DuplicateOp'],
  ['rh8.O((qo5)', 'qo5 Id'],
  ['fsi.b0((vy7)', 'vy7 Margins'],
  ['apb.Y((fqa)', 'fqa Point'],
  ['ddj.b((ukb)', 'ukb RecordingSegment'],
  ['ldj.A2((bmb)', 'bmb Rect'],
  ['aa6.x0((ua0)', 'ua0'],
  ['efj.b((cwb)', 'cwb ReplyAnchor'],
  ['nti.X((cxc)', 'cxc SeqId (yec default)'],
];
for (const [fn, name] of structWriters) {
  ok(yec.includes(`Integer.valueOf(${fn}`), `yec -> ${fn} = ${name}`);
}

// ywd-anon struct writers in z0c
for (const [fn, name] of [
  ['apb.Z((qed)', 'qed Size'],
  ['wtf.b((utf)', 'utf Uuid'],
  ['rz1.b0((v01)', 'v01 Boundary'],
  ['y5j.c((hd1)', 'hd1 CanvasAnchor'],
  ['z5c.P((hu1)', 'hu1 Color'],
]) {
  ok(z0c.includes(`iZ = ${fn}`), `ywd -> ${fn} = ${name}`);
}

// yyd StyleMap inline writer (ywd case1: t(4,20)+floats+nested t(4,8)+w)
ok(/aVar2\.t\(4, 20\);\s*aVar2\.v\(fC\);\s*aVar2\.v\(fD\);\s*aVar2\.t\(4, 8\);\s*aVar2\.v\(fD2\);\s*aVar2\.v\(fC2\);\s*aVar2\.w\(iF\)/.test(z0c), 'yyd = inline 20B+8B nested struct write');

// table writer functions (ywd cee branches)
const tableWriters = [
  ['tsi.c((uf7)', 'uf7 Line'], ['j0j.e((td8)', 'td8 ModifyBlock'],
  ['l0j.c((vd8)', 'vd8 ModifyGroup'], ['fwi.c((gd)', 'gd AddPathElements'],
  ['o0j.f((wd8)', 'wd8 ModifyInk'], ['r0j.d((ge8)', 'ge8 ModifyPage'],
  ['v0j.d((he8)', 'he8 ModifyParagraphStyle'], ['p0j.d((ee8)', 'ee8'],
  ['w0j.d((ie8)', 'ie8 ModifyPosition'], ['x0j.m((je8)', 'je8 ModifyPositions'],
  ['z0j.l((ke8)', 'ke8 ModifyRecording'], ['a1j.c((le8)', 'le8 ModifyShape'],
  ['c1j.c((me8)', 'me8 ModifyStyle'], ['n4j.c((oz8)', 'oz8 NormalShape'],
  ['q4j.b((r29)', 'r29 NoteBundle'], ['q5j.b((q89)', 'q89 NoteMutationResponse'],
  ['zq9.d((uq9)', 'uq9 Op'], ['w6j.c((vq9)', 'vq9 OpAck'],
  ['x6j.b((vt9)', 'vt9'], ['kvi.f((p9)', 'p9 AckEvent'],
  ['vv7.L((nz9)', 'nz9'], ['fag.n0((k3a)', 'k3a Paper'],
  ['j7j.c((sw9)', 'sw9'],
];
for (const [fn, name] of tableWriters) {
  ok(z0c.includes(`iZ = ${fn}`), `table writer ${fn} = ${name}`);
}

console.log(`\nz0c-writer-map replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
