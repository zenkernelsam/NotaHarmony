// Phase 857 — u5j 操作工厂 + ka4 校验契约登记回归
// 证据：docs/migration/evidence/phase-857-op-factory-validation.md
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const HARM = 'note/src/main/ets';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

// ---- u5j 工厂注册表 ----
const u5j = readFileSync(join(SRC, 'u5j.java'), 'utf8');
const factories = [...u5j.matchAll(/public static( final)? [a-z0-9]+ [a-zA-Z]\(/g)];
ok(factories.length === 25, `u5j has 25 static factory methods (got ${factories.length})`);
const returns = new Set([...u5j.matchAll(/public static( final)? ([a-z0-9]+) [a-zA-Z]\(/g)].map(m => m[2]));
for (const t of ['wd8', 'td8', 'le8', 'ge8', 'he8', 'je8', 'ke8', 'me8', 'vd8',
                 'pub', 'qub', 'cee', 'f2c', 'l2d', 'mqf', 'gd', 'rl2', 'dm2', 'ln2', 'ao2']) {
  ok(returns.has(t), `u5j factory returns table ${t}`);
}
ok(u5j.match(/[a-zA-Z]\(x09 x09Var/g) !== null, 'all u5j factories take x09 (builder) first arg');

// ---- ka4 校验接口 ----
const ka4Impls = readdirSync(SRC)
  .filter(f => f.endsWith('.java') && readFileSync(join(SRC, f), 'utf8').includes('implements ka4'));
ok(ka4Impls.length === 82, `82 ka4 implementors (got ${ka4Impls.length})`);
const msgs = new Set();
for (const f of ka4Impls) {
  for (const m of readFileSync(join(SRC, f), 'utf8')
    .matchAll(/return "(Cannot|Must|Invalid|Unable|Expected|Should|Duplicate|At least|Only|No )[^"]*"/g)) {
    msgs.add(m[0]);
  }
}
ok(msgs.size === 33, `33 ka4 validation messages (got ${msgs.size})`);
ok([...msgs].some(m => m.includes('same target twice')), 'ka4 has same-target-twice gate');
ok([...msgs].some(m => m.includes('more than 0 pages')), 'ka4 has >0-pages gate');
ok([...msgs].some(m => m.includes('non-Math Block')), 'ka4 has math-on-non-Math gate');

// ---- Harmony 等价校验 ----
const dataFiles = readdirSync(join(HARM, 'data')).filter(f => f.endsWith('.ets'));
const gates = new Set();
for (const f of dataFiles) {
  for (const m of readFileSync(join(HARM, 'data', f), 'utf8')
    .matchAll(/throw new Error\('original [A-Z_]+ [^']+'/g)) {
    gates.add(m[0]);
  }
}
ok(gates.size === 31, `31 Harmony encoder throw-gates (got ${gates.size})`);
const inkEnc = readFileSync(join(HARM, 'data/OriginalModifyInkPayloadEncoder.ets'), 'utf8');
ok(inkEnc.includes('repeats a target Ink'), 'MODIFY_INK repeats-target gate (ka4 same-target-twice)');
ok((inkEnc.match(/throw new Error/g) || []).length >= 6, 'MODIFY_INK has >=6 validation gates');
const codec = readFileSync(join(HARM, 'data/BinaryOpCodec.ets'), 'utf8');
ok(codec.includes('invalid operation magic'), 'BinaryOpCodec magic gate');
ok(codec.includes('byte budget'), 'BinaryOpCodec byte-budget gate');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
