// Phase 898 — ar6 schema 里程碑枚举回归
// 证据：docs/migration/evidence/phase-898-ar6-schema-enum.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const ar6 = rd('ar6.java');

ok(ar6.includes('public final class ar6'), 'ar6 enum class');
const milestones = [
  'PRE_SHIPPING((short) 0)', 'ALPHA_1((short) 1)', 'LAYOUT_MODE((short) 2)',
  'CHECKBOX_OP((short) 3)', 'SHAPES_FORCE((short) 4)',
  'TEXTBOX_MARGINS_AND_RESIZING_TO_FIT_TEXT((short) 5)',
  'DECORATOR_STYLE((short) 6)', 'BLOCKS_AND_SHAPES_POSITION_LOCK((short) 7)',
  'PEER_INTERACTION((short) 8)', 'TAPE_PATTERN((short) 9)',
  'WRITING_DIRECTION((short) 10)', 'CODE_AND_CALLIGRAPHY((short) 11)',
  'COMMENTS((short) 12)', 'MODIFY_INK_TAPE_PATTERN((short) 13)',
  'BLOCK_WRAP_SUPPORT((short) 14)', 'INK_EFFECT(15)',
];
for (const m of milestones) {
  ok(ar6.includes(m), `ar6 ${m.split('(')[0]}`);
}
ok(ar6.includes('public static final ar6 K = new ar6(15)'),
  'ar6.K current = 15 INK_EFFECT');
ok(ar6.includes('public final short I'), 'ar6 short value');
ok(ar6.includes('new zq6(0)'), 'ar6 values-array holder');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
