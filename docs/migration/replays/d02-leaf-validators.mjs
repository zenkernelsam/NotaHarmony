// Phase 897 — 叶子校验体 + vy7 字段序 + ymf 回归
// 证据：docs/migration/evidence/phase-897-leaf-validators.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const k3a = rd('k3a.java');
const vy7 = rd('vy7.java');
const qed = rd('qed.java');
const fqa = rd('fqa.java');
const ymf = rd('ymf.java');

// ---- 叶子校验体 ----
ok(k3a.includes('Paper background colors must be alpha == 1'),
  'k3a.a alpha==0xFF rule');
ok(k3a.includes('hu1VarJ.c() & 255'), 'k3a.a unsigned alpha read');
ok(vy7.includes('Margins cannot be negative'), 'vy7.a nonneg rule');
ok(vy7.includes('ddg.l("left"') && vy7.includes('ddg.l("right"') &&
   vy7.includes('ddg.l("top"') && vy7.includes('ddg.l("bottom"'),
  'vy7.a per-side finite');
ok(qed.includes('return ddg.i(this)'), 'qed.a = ddg.i');
ok(fqa.includes('return ddg.h(this)'), 'fqa.a = ddg.h');

// ---- vy7 字段序 TBLR ----
ok(vy7.includes('getFloat(this.I + 4)') && vy7.includes('getFloat(this.I + 8)') &&
   vy7.includes('getFloat(this.I + 12)'), 'vy7 float accessors +4/+8/+12');
// 语义序：f()=top(+0), c()=bottom(+4), d()=left(+8), e()=right(+12)
ok(vy7.match(/float c\(\)[\s\S]{0,80}getFloat\(this\.I \+ 4\)/),
  'vy7 c()=+4 bottom');
ok(vy7.match(/float d\(\)[\s\S]{0,80}getFloat\(this\.I \+ 8\)/),
  'vy7 d()=+8 left');
ok(vy7.match(/float e\(\)[\s\S]{0,80}getFloat\(this\.I \+ 12\)/),
  'vy7 e()=+12 right');

// ---- ymf = UShort ----
ok(ymf.includes('public final class ymf implements Comparable'),
  'ymf Comparable value class');
ok(ymf.includes('public final short I'), 'ymf short field');
ok(ymf.includes('return a(this.I)'), 'ymf toString unsigned format');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
