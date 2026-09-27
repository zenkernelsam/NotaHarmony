// Phase 924 — haa 32 值 payload-type 枚举回归
// 证据：docs/migration/evidence/phase-924-haa-enum.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const haa = rd('haa.java');
const zq9 = rd('zq9.java');

// full ordinal backbone
const EXPECTED = [
  'NONE', 'SET_METADATA', 'ASSET_CLOUD_PERSISTED', 'CREATE_PAGE',
  'MODIFY_PAGE', 'CREATE_RECORDING', 'MODIFY_RECORDING',
  'INSERT_CHAR', 'INSERT_STRING', 'REMOVE_CHAR', 'REMOVE_CHARS',
  'REVIVE_CHARS', 'MODIFY_STYLE', 'MODIFY_PARAGRAPH_STYLE',
  'CLEAR_STYLE', 'CREATE_INK', 'ADD_PATH_ELEMENTS', 'MODIFY_INK',
  'CREATE_SHAPE', 'MODIFY_SHAPE', 'CREATE_GROUP', 'MODIFY_GROUP',
  'CREATE_BLOCK', 'MODIFY_BLOCK', 'MODIFY_POSITIONS',
  'DELETE_ENTITIES', 'TRANSIENT_INTERACTION_ENDED',
  'MODIFY_PDF_FIELD', 'UPDATE_CHECKBOX', 'PEER_INTERACTION',
  'CREATE_COMMENT', 'MODIFY_COMMENT'];

EXPECTED.forEach((name, i) => {
  ok(haa.includes(`${name}((byte) ${i})`), `haa.${name} = ${i}`);
});

// zq9 pairs every non-NONE type with its class
for (const cls of ['l2d','ra0','ln2','ge8','yn2','ke8','e46','f46','pub',
  'qub','f2c','me8','he8','io1','dm2','gd','wd8','ao2','le8','cm2',
  'vd8','rl2','td8','je8','s83','tdf','ee8','mqf','yda','tl2','ud8'])
  ok(zq9.includes(`${cls}.class`), `zq9 registers ${cls}`);

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
