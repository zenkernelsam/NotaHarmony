// Phase 921 — 枚举 setter 族 + 枚举值全集回归
// 证据：docs/migration/evidence/phase-921-enum-closure.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

// setter names
ok(rd('o2d.java').includes('SetParagraphAlignment(value='), 'o2d = SetParagraphAlignment');
ok(rd('j2d.java').includes('SetDecoratorStyle(value='), 'j2d = SetDecoratorStyle');
ok(rd('a3d.java').includes('SetUInt8(value='), 'a3d = SetUInt8');
ok(rd('b3d.java').includes('SetWritingDirection(value='), 'b3d = SetWritingDirection');
ok(rd('n2d.java').includes('SetPaper(value='), 'n2d = SetPaper');
ok(rd('p2d.java').includes('SetRect(value='), 'p2d = SetRect');

// setter payload types
ok(rd('o2d.java').match(/r4a j\(\)/), 'o2d payload r4a');
ok(rd('j2d.java').match(/fy2 j\(\)/), 'j2d payload fy2');
ok(rd('a3d.java').match(/cmf j\(\)/), 'a3d payload cmf UByte');
ok(rd('b3d.java').match(/bcg k\(\)/), 'b3d payload bcg');
ok(rd('n2d.java').match(/k3a j\(\)/), 'n2d payload k3a');
ok(rd('p2d.java').match(/bmb j\(\)/), 'p2d payload bmb');

// enum values
ok(rd('r4a.java').includes('LEFT((byte) 1)') && rd('r4a.java').includes('RIGHT((byte) 3)'),
  'r4a alignment 1-based {LEFT,CENTER,RIGHT}');
const fy2 = rd('fy2.java');
ok(fy2.includes('NONE((byte) 0)') && fy2.includes('CHECK_BOX((byte) 3)') &&
   fy2.includes('CODE_BLOCK((byte) 5)'), 'fy2 DecoratorStyle 6 values');
ok(rd('bcg.java').includes('LEFT_TO_RIGHT((byte) 0)') &&
   rd('bcg.java').includes('RIGHT_TO_LEFT((byte) 1)'), 'bcg WritingDirection');
const ife = rd('ife.java');
ok(ife.includes('STRIPES((byte) 0)') && ife.includes('CHECKERS((byte) 8)') &&
   ife.includes('WAVES((byte) 7)'), 'ife TapePattern 9 values');
ok(rd('ive.java').includes('PIXEL_ALIGN((byte) 0)') &&
   rd('ive.java').includes('NO_WRAP((byte) 1)'), 'ive TextWrap');
// cmf = UByte
const cmf = rd('cmf.java');
ok(cmf.includes('implements Comparable') && cmf.includes('I & 255'),
  'cmf = Kotlin UByte value class');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
