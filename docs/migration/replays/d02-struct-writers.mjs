// Phase 969 — 内联结构写器字节序（wtf.b/rz1.b0/apb.Z/y5j.c/efj.b）
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const wtf = readFileSync(`${ROOT}/wtf.java`, 'utf8');
const rz1 = readFileSync(`${ROOT}/rz1.java`, 'utf8');
const apb = readFileSync(`${ROOT}/apb.java`, 'utf8');
const y5j = readFileSync(`${ROOT}/y5j.java`, 'utf8');
const efj = readFileSync(`${ROOT}/efj.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// wtf.b utf 16B: t(8,16) + push low then high
ok(/static final int b\(utf utfVar, a aVar\)/.test(wtf), 'wtf.b = utf writer');
ok(/aVar\.t\(8, 16\);[\s\S]{0,40}aVar\.x\(jC\);[\s\S]{0,40}aVar\.x\(jD\);[\s\S]{0,20}aVar\.r\(\)/.test(wtf), 'wtf: t(8,16)+x(low)+x(high)');
ok(/jC == 0 && jD == 0\) \? ttf\.K/.test(wtf), 'wtf.e: all-zero uuid -> ttf.K');

// rz1.b0 v01 16B: pad3 + boundType byte + nested cxc 12B
ok(/static final int b0\(v01 v01Var, a aVar\)/.test(rz1), 'rz1.b0 = v01 writer');
ok(/aVar\.t\(4, 16\);[\s\S]{0,20}aVar\.s\(3\);[\s\S]{0,20}aVar\.u\(b2\);/.test(rz1), 'v01: pad3 + y01 byte @12');
ok(/aVar\.t\(4, 12\);[\s\S]{0,20}aVar\.w\(iC\);[\s\S]{0,20}aVar\.w\(iD\);[\s\S]{0,20}aVar\.s\(2\);[\s\S]{0,20}aVar\.y\(sC\);/.test(rz1), 'v01: nested cxc idx/ts/pad2/site');
ok(/byte b2 = y01VarD\.I/.test(rz1), 'v01: boundaryType = y01.I byte');

// apb.Z qed 8B
ok(/static final int Z\(qed qedVar, a aVar\)/.test(apb), 'apb.Z = qed writer');
ok(/aVar\.t\(4, 8\);[\s\S]{0,30}aVar\.v\(fC\);[\s\S]{0,30}aVar\.v\(fD\);/.test(apb), 'qed: t(4,8)+two floats');

// y5j.c hd1 20B: nested fqa@c(12..19) + cxc@0..11
ok(/static final int c\(hd1 hd1Var, a aVar\)/.test(y5j), 'y5j.c = hd1 writer');
ok(/aVar\.t\(4, 20\);[\s\S]{0,30}aVar\.t\(4, 8\);[\s\S]{0,40}aVar\.v\(fD\);[\s\S]{0,30}aVar\.v\(fC\);[\s\S]{0,40}aVar\.t\(4, 12\);[\s\S]{0,30}aVar\.w\(iC\);[\s\S]{0,30}aVar\.w\(iD\);[\s\S]{0,30}aVar\.s\(2\);[\s\S]{0,30}aVar\.y\(sC\);/.test(y5j), 'hd1: 20B nested fqa+cxc write order');

// efj.b cwb 8B: nested qo5
ok(/static final int b\(cwb cwbVar, a aVar\)/.test(efj), 'efj.b = cwb writer');
ok(/aVar\.t\(4, 8\);[\s\S]{0,30}aVar\.t\(4, 8\);[\s\S]{0,40}aVar\.w\(iD\);[\s\S]{0,30}aVar\.s\(2\);[\s\S]{0,30}aVar\.y\(sC\);/.test(efj), 'cwb: 8B nested qo5 (ts/pad/site)');

console.log(`\nstruct-writers replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
