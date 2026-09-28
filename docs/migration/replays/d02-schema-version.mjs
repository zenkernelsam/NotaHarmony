// Phase 980 — ar6 SchemaVersion 枚举 0-15 + rgc.a 委托
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const ar6 = readFileSync(`${ROOT}/ar6.java`, 'utf8');
const rgc = readFileSync(`${ROOT}/rgc.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

const V = [
  'PRE_SHIPPING((short) 0)',
  'ALPHA_1((short) 1)',
  'LAYOUT_MODE((short) 2)',
  'CHECKBOX_OP((short) 3)',
  'SHAPES_FORCE((short) 4)',
  'TEXTBOX_MARGINS_AND_RESIZING_TO_FIT_TEXT((short) 5)',
  'DECORATOR_STYLE((short) 6)',
  'BLOCKS_AND_SHAPES_POSITION_LOCK((short) 7)',
  'PEER_INTERACTION((short) 8)',
  'TAPE_PATTERN((short) 9)',
  'WRITING_DIRECTION((short) 10)',
  'CODE_AND_CALLIGRAPHY((short) 11)',
  'COMMENTS((short) 12)',
  'MODIFY_INK_TAPE_PATTERN((short) 13)',
  'BLOCK_WRAP_SUPPORT((short) 14)',
  'INK_EFFECT(15)',
];
for (const v of V) ok(ar6.includes(v), `ar6: ${v.split('(')[0]}`);

// K = current = 15; payload short I
ok(/public static final ar6 K = new ar6\(15\)/.test(ar6), 'ar6.K = current version 15 (INK_EFFECT)');
ok(/public final short I/.test(ar6), 'ar6.I = short payload');

// rgc.a delegates to ar6.K.I
ok(/public static final short a;/.test(rgc), 'rgc.a = static short');
ok(/a = ar6\.K\.I/.test(rgc), 'rgc.a = ar6.K.I (=15)');

// consumers: q4j.c writes it, nce compares it
const q4j = readFileSync(`${ROOT}/q4j.java`, 'utf8');
const nce = readFileSync(`${ROOT}/nce.java`, 'utf8');
ok(/aVar\.i\(7, rgc\.a\)/.test(q4j), 'q4j.c: f7 schemaVersion = rgc.a');
ok(/rgc\.a & 65535/.test(nce), 'nce: u16 compare vs rgc.a');

console.log(`\nschema-version replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
