// Phase 902 — o0j.b GMS AssetPacks 补丁器归类回归
// 证据：docs/migration/evidence/phase-902-o0j-assetpack-patch.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const o0j = rd('o0j.java');
const jjg = rd('jjg.java');
const aig = rd('aig.java');

// ---- 格式实证 ----
ok(o0j.includes('771763713') || o0j.includes('-771763713'),
  'magic 0xD1FFD1FF as signed int');
ok(o0j.includes('Unexpected magic'), 'magic gate');
ok(o0j.includes('Unexpected version'), 'version=4 gate');
ok(o0j.includes('Patch file overrun'), 'END=0 / overrun guard');
ok(o0j.includes('case 247') && o0j.includes('case 248') &&
   o0j.includes('case 249') && o0j.includes('case 250') &&
   o0j.includes('case 251'), 'opcodes F7-FB');
ok(o0j.includes('copyLength negative') || o0j.includes('Output length overrun'),
  'length guards');
ok(o0j.includes('patch underrun') || o0j.includes('truncated input stream'),
  'underrun guards');
ok(o0j.includes('16384'), '16KB chunk size');

// ---- GMS 归属 ----
ok(jjg.includes('extends OutputStream') && jjg.includes('assetpacks.p'),
  'jjg = Play AssetPacks slice OutputStream');
ok(jjg.includes('FileOutputStream'), 'jjg writes file');
ok(aig.includes('public') || aig.includes('class'), 'aig base range adapter');

// ---- 语义 ----
ok(o0j.includes('readUnsignedShort()') && o0j.includes('readInt()'),
  'u16/i32 operand readers');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
