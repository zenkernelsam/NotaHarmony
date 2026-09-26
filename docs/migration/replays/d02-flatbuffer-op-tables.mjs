// Phase 856 — 操作流 FlatBuffer 序列化层登记回归
// 证据：docs/migration/evidence/phase-856-flatbuffer-op-tables.md
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources';
const SRC103 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources';
const HARM = 'note/src/main/ets';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

// ---- 原版 1.4.2：flatbuffer 触点与表写入器 ----
const defs = readdirSync(join(SRC, 'defpackage')).filter(f => f.endsWith('.java'));
let fbFiles = 0, writers = 0;
for (const f of defs) {
  const s = readFileSync(join(SRC, 'defpackage', f), 'utf8');
  if (!s.includes('flatbuffers')) continue;
  fbFiles++;
  if (/\w+\.D\(\d+\)/.test(s)) writers++;
}
ok(fbFiles === 133, `1.4.2 flatbuffer files = 133 (got ${fbFiles})`);
ok(writers === 65, `1.4.2 table writers (D-call) = 65 (got ${writers})`);

const dCalls = (cls) =>
  [...readFileSync(join(SRC, 'defpackage', cls + '.java'), 'utf8')
    .matchAll(/\w+\.D\((\d+)\)/g)].map(m => +m[1]);
ok(dCalls('fcn').includes(19), 'fcn carries D(19) — wd8-equivalent ink table');
ok(dCalls('n6n').includes(19), 'n6n carries D(19) — second 19-field op table');
ok(dCalls('rbn').includes(21), 'rbn carries D(21) — largest single table');
ok(dCalls('k2h').filter(n => n === 19).length === 2, 'k2h carries two D(19) subtables');
ok(dCalls('y6n').includes(18), 'y6n carries D(18) — td8-equivalent shape table');

// ---- 原版 1.0.3：移植基线的表读取器 ----
for (const cls of ['wd8', 'le8', 'td8']) {
  const p = join(SRC103, 'defpackage', cls + '.java');
  let okFile = true;
  try { readFileSync(p); } catch { okFile = false; }
  ok(okFile, `1.0.3 table reader ${cls}.java exists`);
}
const fb103 = readdirSync(join(SRC103, 'defpackage'))
  .filter(f => f.endsWith('.java') &&
    readFileSync(join(SRC103, 'defpackage', f), 'utf8').includes('import com.google.flatbuffers')).length;
ok(fb103 === 91, `1.0.3 flatbuffer imports = 91 (got ${fb103})`);

// ---- zstd：厂商支持而非协议层 ----
let zstdCalls = 0;
for (const f of defs) {
  const s = readFileSync(join(SRC, 'defpackage', f), 'utf8');
  if (/\bZstd\.[a-zA-Z]/.test(s)) zstdCalls++;
}
ok(zstdCalls === 0, `no direct Zstd.* calls in app code (got ${zstdCalls})`);

// ---- Harmony 侧：18 个 ORIGINAL_* 扁平缓冲操作 ----
const opTypes = readFileSync(join(HARM, 'core/model/OpTypes.ets'), 'utf8');
const originals = [...opTypes.matchAll(/ORIGINAL_[A-Z_]+ = (\d+)/g)]
  .map(m => +m[1]).filter(n => n >= 60 && n <= 78);
ok(originals.length === 19, `19 ORIGINAL_* flatbuffer op types 60..78 (got ${originals.length})`);
ok(originals.length === new Set(originals).size, 'ORIGINAL_* op ids are unique');

// ---- 编码器字段数引用与原版 D(n) 一致 ----
const enc = (n) => readFileSync(join(HARM, 'data', n), 'utf8');
ok(enc('OriginalModifyInkPayloadEncoder.ets').includes('19 fields'), 'MODIFY_INK cites wd8 19 fields');
ok(enc('OriginalModifyShapePayloadEncoder.ets').includes('17 fields'), 'MODIFY_SHAPE cites le8 17 fields');
ok(enc('OriginalModifyBlockPayloadEncoder.ets').includes('18 fields'), 'MODIFY_BLOCK cites td8 18 fields');
const encoders = readdirSync(join(HARM, 'data')).filter(f => /^Original.*PayloadEncoder\.ets$/.test(f));
ok(encoders.length >= 15, `>=15 Original*PayloadEncoder files (got ${encoders.length})`);

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
