// Phase 874 — setter 包装族 + op 枚举登记回归
// 证据：docs/migration/evidence/phase-874-setter-enum-registry.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

// ---- setter 包装族：{f0: T} 单字段 ----
const wrappers = [['k2d', 'Float'], ['y2d', 'qed'], ['z2d', 'String'],
                  ['g2d', 'hu1'], ['p2d', 'bmb'], ['n2d', 'k3a']];
for (const [cls, type] of wrappers) {
  const body = readFileSync(join(SRC, `${cls}.java`), 'utf8');
  const fields = new Set([...body.matchAll(/c\((\d+)\)/g)].map(m => (+m[1] - 4) / 2));
  ok(fields.size === 1 && fields.has(0), `${cls} = single-field wrapper`);
  ok(new RegExp(`${type} j\\(\\)[\\s\\S]{0,200}c\\(4\\)`).test(body),
    `${cls}.f0 = ${type}`);
}

// ---- 枚举集 ----
const enums = {
  u16: ['PEN', 'PENCIL', 'HIGHLIGHTER', 'TAPE', 'WHOLE_ERASER', 'PARTIAL_ERASER', 'SELECTION', 'LASER'],
  t16: ['VARIABLE_WIDTH', 'FIXED_WIDTH', 'DASH', 'DOTS'],
  ife: ['STRIPES', 'GRID', 'DOTS', 'PLAIN', 'STARS', 'FLOWERS', 'HEARTS', 'WAVES', 'CHECKERS'],
  z4d: ['NONE', 'LINE', 'POLYGON', 'NORMAL_SHAPE'],
  ty0: ['SQUARE', 'ROUND'],
  ive: ['PIXEL_ALIGN', 'NO_WRAP'],
  im: ['NONE', 'CANVAS_ANCHOR', 'TEXT_ANCHOR', 'ENTITY_ANCHOR', 'REPLY_ANCHOR'],
};
for (const [cls, names] of Object.entries(enums)) {
  const body = readFileSync(join(SRC, `${cls}.java`), 'utf8');
  for (const name of names) {
    ok(body.includes(`${name}((byte)`), `${cls}.${name}`);
  }
}

// ---- Harmony u16 线层解码 ----
const cio = readFileSync('note/src/main/ets/data/OriginalCreateInkOperation.ets', 'utf8');
ok(cio.includes('tool === 3'), 'tool==3 = TAPE');
ok(cio.includes('tool === 1'), 'tool==1 = PENCIL');
ok(cio.includes('tool === 2'), 'tool==2 = HIGHLIGHTER');
ok(cio.includes('tool === 5'), 'tool==5 = PARTIAL_ERASER');
ok(cio.includes('normalizeOriginalEnum(table.readUint8(4, 0), 7)'),
  'tool field read as u8 with u16 range bound');
ok(cio.includes('payload.tool !== 0 && payload.tool !== 1 && payload.tool !== 2 && payload.tool !== 3 &&\n    payload.tool !== 5'),
  'creatable-ink gate: only 0/1/2/3/5 allowed');
const bt = readFileSync('note/src/main/ets/core/model/BrushTypes.ets', 'utf8');
ok(bt.includes('a6f.R') && bt.includes('LASER'), 'BrushTypes cites UI-layer a6f enum (not wire u16)');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
