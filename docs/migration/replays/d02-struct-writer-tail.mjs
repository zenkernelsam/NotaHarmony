// Phase 974 — vfj.d xq3 / fsi.b0 vy7 / ddj.b ukb / aa6.x0 ua0
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const vfj = readFileSync(`${ROOT}/vfj.java`, 'utf8');
const fsi = readFileSync(`${ROOT}/fsi.java`, 'utf8');
const ddj = readFileSync(`${ROOT}/ddj.java`, 'utf8');
const aa6 = readFileSync(`${ROOT}/aa6.java`, 'utf8');
const vy7 = readFileSync(`${ROOT}/vy7.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// vfj.d xq3 DuplicateOp 24B: t(8,24) + 2 longs + nested qo5
ok(/static final int d\(xq3 xq3Var, a aVar\)/.test(vfj), 'vfj.d = xq3 writer');
ok(/aVar\.t\(8, 24\);[\s\S]{0,30}aVar\.x\(jC\);[\s\S]{0,30}aVar\.x\(jE\);/.test(vfj), 'xq3: t(8,24) + 2 longs @8/@16');
ok(/aVar\.t\(4, 8\);[\s\S]{0,30}aVar\.w\(iD\);[\s\S]{0,30}aVar\.s\(2\);[\s\S]{0,30}aVar\.y\(sC\);/.test(vfj), 'xq3: nested qo5 @0 (ts/pad/site)');

// fsi.b0 vy7 Margins 16B: 4 floats
ok(/static final int b0\(vy7 vy7Var, a aVar\)/.test(fsi), 'fsi.b0 = vy7 writer');
ok(/aVar\.t\(4, 16\);[\s\S]{0,30}aVar\.v\(fE\);[\s\S]{0,30}aVar\.v\(fD\);[\s\S]{0,30}aVar\.v\(fC\);[\s\S]{0,30}aVar\.v\(f\);/.test(fsi), 'vy7: t(4,16) + 4 floats');
ok(/Margins\(top=/.test(vy7) && /bottom=/.test(vy7), 'vy7 = Margins{top,bottom,left,right}');
ok(/Margins cannot be negative/.test(vy7) && /ddg\.l\("left"/.test(vy7), 'vy7: ddg.l per-field negative check');

// ddj.b ukb 16B: 2 longs
ok(/static final int b\(ukb ukbVar, a aVar\)/.test(ddj), 'ddj.b = ukb writer');
ok(/aVar\.t\(8, 16\);[\s\S]{0,30}aVar\.x\(jC\);[\s\S]{0,30}aVar\.x\(jD\);/.test(ddj), 'ukb: t(8,16) + 2 longs {start@0,end@8}');

// aa6.x0 ua0 64B: 8 longs
ok(/static final int x0\(ua0 ua0Var, a aVar\)/.test(aa6), 'aa6.x0 = ua0 writer');
ok(/aVar\.t\(8, 64\);[\s\S]{0,200}aVar\.x\(j\);[\s\S]{0,30}aVar\.x\(jI\);[\s\S]{0,30}aVar\.x\(jH\);[\s\S]{0,30}aVar\.x\(jG\);[\s\S]{0,30}aVar\.x\(jF\);[\s\S]{0,30}aVar\.x\(jE\);[\s\S]{0,30}aVar\.x\(jD\);[\s\S]{0,30}aVar\.x\(jC\);/.test(aa6), 'ua0: t(8,64) + 8 longs j..c');

console.log(`\nstruct-writer-tail replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
