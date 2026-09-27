// Phase 871 — 形状/组 op payload（类型 18–21）登记回归
// 证据：docs/migration/evidence/phase-871-shape-group-payloads.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

// ---- zq9 映射 ----
const zq9 = readFileSync(join(SRC, 'zq9.java'), 'utf8');
ok(zq9.includes('ao2.class), haa.CREATE_SHAPE'), 'CREATE_SHAPE -> ao2');
ok(zq9.includes('le8.class), haa.MODIFY_SHAPE'), 'MODIFY_SHAPE -> le8');
ok(zq9.includes('cm2.class), haa.CREATE_GROUP'), 'CREATE_GROUP -> cm2');
ok(zq9.includes('vd8.class), haa.MODIFY_GROUP'), 'MODIFY_GROUP -> vd8');

// ---- ao2 CREATE_SHAPE：17 槽 ----
const ao2 = readFileSync(join(SRC, 'ao2.java'), 'utf8');
const ao2Fields = new Set([...ao2.matchAll(/c\((\d+)\)/g)].map(m => (+m[1] - 4) / 2));
ok(ao2Fields.size === 17, `ao2 has 17 fields (got ${ao2Fields.size})`);
ok(/cxc r\(\)[\s\S]{0,80}c\(4\)/.test(ao2), 'ao2 f0 = cxc position');
ok(/qed u\(\)[\s\S]{0,80}c\(10\)/.test(ao2), 'ao2 f3 = qed size');
ok(/u16 y\(\)[\s\S]{0,80}c\(16\)/.test(ao2), 'ao2 f6 = u16 struct');
ok(/hu1 k\(\)[\s\S]{0,80}c\(22\)/.test(ao2), 'ao2 f9 = hu1 color');
ok(/hu1 m\(\)[\s\S]{0,80}c\(26\)/.test(ao2), 'ao2 f11 = hu1 fill color');
ok(/long o\(\)[\s\S]{0,80}c\(36\)/.test(ao2), 'ao2 f16 = long');

// ---- le8 MODIFY_SHAPE：锚点 ----
const le8 = readFileSync(join(SRC, 'le8.java'), 'utf8');
ok(/hu1 l\(\)[\s\S]{0,80}c\(24\)/.test(le8), 'le8 f10 = hu1 color');
ok(/Float k\(\)[\s\S]{0,80}c\(26\)/.test(le8), 'le8 f11 = Float borderWidth');
ok(/g2d j\(g2d g2dVar\)[\s\S]{0,300}c\(28\)/.test(le8), 'le8 f12 = g2d fill-color setter');
ok(/Boolean s\(\)[\s\S]{0,80}c\(32\)/.test(le8), 'le8 f14 = Boolean lock');
ok(/ife w\(\)[\s\S]{0,80}c\(22\)/.test(le8), 'le8 f8 = ife style');
ok(/cxc r\(\)[\s\S]{0,80}c\(6\)/.test(le8), 'le8 f1 = cxc');
ok(le8.includes('public final String a()'), 'le8 carries ka4 validator');

// ---- cm2/vd8 组表 ----
const cm2 = readFileSync(join(SRC, 'cm2.java'), 'utf8');
const cm2Fields = new Set([...cm2.matchAll(/c\((\d+)\)/g)].map(m => (+m[1] - 4) / 2));
ok(cm2Fields.size === 1 && cm2Fields.has(0), 'cm2 = single members-vector field');
const vd8 = readFileSync(join(SRC, 'vd8.java'), 'utf8');
ok(/qo5 j\(\)[\s\S]{0,80}c\(4\)/.test(vd8), 'vd8 f0 = qo5 group target');
ok(/int k\(\)[\s\S]{0,80}c\(6\)/.test(vd8), 'vd8 f1 = member vector count');

// ---- Harmony 等价 ----
const mse = readFileSync('note/src/main/ets/data/OriginalModifyShapePayloadEncoder.ets', 'utf8');
ok(mse.includes('new Array<number>(17)'), 'Harmony writes 17-slot le8 vtable');
ok(mse.includes('le8 has 17 fields'), 'encoder cites le8 field count');
ok(mse.includes('fields[10] = update.color === null ? 0 : 12'), 'fields[10]=color (hu1)');
ok(mse.includes('fields[11] = update.borderWidth === null ? 0 : 16'), 'fields[11]=borderWidth');
ok(mse.includes('fields[12] = update.fillColorPresent ? 20 : 0'), 'fields[12]=fillColor');
ok(mse.includes('fields[14] = update.positionLocked === null ? 0 : 24'), 'fields[14]=lock');
ok(mse.includes('u5j.x'), 'encoder cites u5j.x factory');
const gpe = readFileSync('note/src/main/ets/data/OriginalGroupPayloadEncoder.ets', 'utf8');
ok(gpe.includes('encodeOriginalCreateGroup') && gpe.includes('writeMembers'),
  'Harmony writes cm2 members vector');
ok(gpe.includes('writeU16(bytes, offset, members[index].siteId)'),
  'member = qo5 siteId+timestamp struct');
ok(gpe.includes('original Group repeats a member'), 'duplicate-member validation');
const gmc = readFileSync('note/src/main/ets/data/OriginalGroupMutationOpCodec.ets', 'utf8');
ok(gmc.length > 500, 'GroupMutation codec exists (vd8)');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
