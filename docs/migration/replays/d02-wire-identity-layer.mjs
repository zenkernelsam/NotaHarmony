// Phase 859 — 线协议身份层（haa/uq9/qo5/r29/utf）登记回归
// 证据：docs/migration/evidence/phase-859-wire-identity-layer.md
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const HARM = 'note/src/main/ets/data';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

// ---- haa payload-type 枚举：32 项 ----
const haa = readFileSync(join(SRC, 'haa.java'), 'utf8');
const haaVals = [...haa.matchAll(/([A-Z_]+)\(\(byte\) (\d+)\)/g)]
  .map(m => [m[1], +m[2]]);
ok(haaVals.length === 32, `haa has 32 payload types (got ${haaVals.length})`);
const haaMap = Object.fromEntries(haaVals);
for (const [name, v] of [['SET_METADATA', 1], ['CREATE_INK', 15],
    ['ADD_PATH_ELEMENTS', 16], ['MODIFY_INK', 17], ['DELETE_ENTITIES', 25],
    ['UPDATE_CHECKBOX', 28], ['CREATE_COMMENT', 30], ['MODIFY_COMMENT', 31]]) {
  ok(haaMap[name] === v, `haa ${name} = ${v}`);
}
ok(haaMap.NONE === 0, 'haa NONE = 0 (excluded sentinel)');

// ---- uq9 Op 信封字段 ----
const uq9 = readFileSync(join(SRC, 'uq9.java'), 'utf8');
ok(uq9.includes('extends cee implements ka4'), 'uq9 is cee+ka4');
ok(uq9.includes('No value for (required) field id'), 'uq9 id@0 is required');
ok(/c\(14\).*byteBuffer\.getInt/.test(uq9.replace(/\n/g, ' ')) ||
   uq9.includes('c(14)'), 'uq9 payload@5 present (c(14))');
ok(uq9.includes('c(16)'), 'uq9 transientInteraction@6 present (c(16))');
ok(uq9.includes('Op(id=') && uq9.includes('transientInteraction='),
  'uq9 toString names Op envelope fields');

// ---- qo5 Id ----
const qo5 = readFileSync(join(SRC, 'qo5.java'), 'utf8');
ok(qo5.includes('Id(site=') && qo5.includes('timestamp='),
  'qo5 = Id(site,timestamp)');
ok(/short c\(\)/.test(qo5) && /int d\(\)/.test(qo5), 'qo5 site=short + timestamp=int');

// ---- r29 NoteBundle ----
const r29 = readFileSync(join(SRC, 'r29.java'), 'utf8');
ok(r29.includes('NoteBundle(noteId='), 'r29 = NoteBundle');
for (const tok of ['legacyNoteId=', 'editorSite=', 'editorUserId=',
                   'createdAt=', 'creatorUserId=', 'ops=', 'schemaVersion=']) {
  ok(r29.includes(tok), `r29 toString names ${tok}`);
}
ok(r29.includes('c(4)') && r29.includes('c(18)'), 'r29 fields 0..7 span c(4)..c(18)');

// ---- utf Uuid 内联结构 ----
const utf = readFileSync(join(SRC, 'utf.java'), 'utf8');
ok(utf.includes('extends xwd'), 'utf is inline struct (xwd base)');
ok(utf.includes('Uuid(bitsLow=') && utf.includes('bitsHigh='), 'utf = Uuid bits pair');
ok(utf.includes('getLong(this.I + 8)') && utf.includes('getLong(this.I)'),
  'utf 16-byte layout: bitsLow@+0 bitsHigh@+8');

// ---- Harmony 侧 ----
const fb = readFileSync(join(HARM, 'OriginalSyncedOperationFlatBuffer.ets'), 'utf8');
ok(fb.includes('ORIGINAL_PAYLOAD_TYPE_MIN: number = 1'), 'PAYLOAD_TYPE_MIN = 1');
ok(fb.includes('ORIGINAL_PAYLOAD_TYPE_MAX: number = 31'), 'PAYLOAD_TYPE_MAX = 31');
ok(/requireField\(bytes, root, 0, 8, 'id'\)/.test(fb), 'envelope id@0 required 8 bytes');
ok(/readU16\(bytes, root\.table \+ idOffset\)/.test(fb), 'id.siteId u16@+0');
ok(/readU32\(bytes, root\.table \+ idOffset \+ 4\)/.test(fb), 'id.timestamp u32@+4');
ok(/fieldOffset\(bytes, root, 5\)/.test(fb), 'payload@5 field');
ok(fb.includes('has no serverTime'), 'synced envelope requires serverTime');

const nb = readFileSync(join(HARM, 'OriginalNoteBundlePageIdentity.ets'), 'utf8');
ok(nb.includes('readInlineBytes(0, 16)'), 'NoteBundle noteId@0 = 16-byte inline UUID');
ok(nb.includes('readTableVector(6,'), 'NoteBundle ops vector @6');
ok(nb.includes('readUint16(7, 0)'), 'NoteBundle schemaVersion @7 u16');
ok(nb.includes('readUint16(2, 0)'), 'NoteBundle editorSiteId @2 u16');

// haa 全 31 值在 Harmony 常量中逐一对应
let missing = 0;
for (const [name, v] of haaVals) {
  if (v === 0) continue;
  const cname = `ORIGINAL_${name}_PAYLOAD_TYPE`;
  let found = false;
  for (const f of readdirSync(HARM).filter(x => x.endsWith('.ets'))) {
    if (readFileSync(join(HARM, f), 'utf8').includes(`${cname}: number = ${v}`)) { found = true; break; }
  }
  if (!found) missing++;
}
ok(missing === 0, `all 31 haa types have ORIGINAL_*_PAYLOAD_TYPE constants (${missing} missing)`);

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
