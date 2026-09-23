// Phase 629 — 剪贴板粘贴源 zIndex 保留：原版 Ink 记录 u6a 携带序列化 z 字段
// `long j`（o8j.java:297 粘贴生产者以 `new xgb(u6aVar2.j)` 原样回填 CreateInk 的
// zIndex 槽位），Shape 记录 ge3 与 Block 记录 ry0 均无 z 字段，其粘贴生产者
// （u5j.j/baj.a）的 xgb 槽恒为 null → 解码端回退 clientTime（顶层）。
// Harmony 对齐：粘贴时按源 elementId 从 original_element_z_index 读回源 z，
// 仅 STROKE 接线（含 cut 源 —— 行在 visible=0 后仍保留 z_index）；
// 无行/多行/非 op-id → undefined → clientTime，与原版 null 路径一致。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const o8j = fs.readFileSync(`${originalRoot}o8j.java`, 'utf8');
const u6a = fs.readFileSync(`${originalRoot}u6a.java`, 'utf8');
const ge3 = fs.readFileSync(`${originalRoot}ge3.java`, 'utf8');
const a5g = fs.readFileSync(`${originalRoot}a5g.java`, 'utf8');
const ks = fs.readFileSync(`${originalRoot}ks.java`, 'utf8');
const hp5 = fs.readFileSync(`${originalRoot}hp5.java`, 'utf8');
const u08 = fs.readFileSync(`${originalRoot}u08.java`, 'utf8');
const kp5 = fs.readFileSync(`${originalRoot}kp5.java`, 'utf8');
const cie = fs.readFileSync(`${originalRoot}cie.java`, 'utf8');
const u5j = fs.readFileSync(`${originalRoot}u5j.java`, 'utf8');
const baj = fs.readFileSync(`${originalRoot}baj.java`, 'utf8');
const persistence = fs.readFileSync('note/src/main/ets/data/StrokePersistence.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const inkEncoder = fs.readFileSync('note/src/main/ets/data/OriginalCreateInkPayloadEncoder.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const shapeEncoder = fs.readFileSync('note/src/main/ets/data/OriginalCreateShapePayloadEncoder.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const blockEncoder = fs.readFileSync('note/src/main/ets/data/OriginalCreateBlockPayloadEncoder.ets', 'utf8')
  .replaceAll('\r\n', '\n');

// --- 原版证据：Ink 记录携带序列化 z（u6a.j long），粘贴原样回填 ---
assert.match(u6a, /public final long j;/);
assert.match(u6a, /public u6a\(cxc cxcVar, fqa fqaVar, Float f, qed qedVar, u16 u16Var, t16 t16Var, ife ifeVar, hu1 hu1Var, float f2, hu1 hu1Var2, long j, List list, xgb xgbVar, mmf mmfVar, y81 y81Var, wx0 wx0Var\)/);
// u5j.g 签名第 16 参为 xgb zIndex；o8j 传入 new xgb(u6aVar2.j)。
assert.match(u5j, /public static final dm2 g\(x09 x09Var, cxc cxcVar, fqa fqaVar, Float f, qed qedVar, u16 u16Var, t16 t16Var, ife ifeVar, hu1 hu1Var, float f2, List list, ArrayList arrayList, ArrayList arrayList2, hu1 hu1Var2, List list2, xgb xgbVar, mmf mmfVar\)/);
assert.match(o8j, /new xgb\(u6aVar2\.j\)/);
// Shape 记录 ge3 无 z 字段（无 long/xgb 成员）；两个 u5j.j 粘贴/识别调用方均传 null。
assert.doesNotMatch(ge3, /xgb|long /);
assert.match(u5j, /public static ao2 j\(x09 x09Var, cxc cxcVar, fqa fqaVar, Float f, v4d v4dVar, u16 u16Var, t16 t16Var, hu1 hu1Var, float f2, hu1 hu1Var2, xgb xgbVar, Float f3, int i\)/);
assert.match(a5g, /u5j\.j\(x09VarC, ge3Var\.c, ge3Var\.e, ge3Var\.g, ge3Var\.f, ge3Var\.h, ge3Var\.i, ge3Var\.j, ge3Var\.k, null, null, ge3Var\.l, 23688\)/);
assert.match(ks, /u5j\.j\(x09VarC, ge3Var\.c, fqaVar, ge3Var\.g, v4dVar, u16Var, ge3Var\.i, hu1Var, ge3Var\.k, null, null, ge3Var\.l, 23688\)/);
// Block 生产者 baj.a 第 10 参为 xgb；hp5/u08/cie/kp5 全部传 null。
assert.match(baj, /ive iveVar, boolean z, xgb xgbVar, dp5 dp5Var/);
for (const src of [hp5, u08, cie, kp5]) {
  assert.match(src, /baj\.a\(/);
}
assert.match(hp5, /ry0Var\.p\(\), null, this\.g/);
assert.match(u08, /ry0Var\.p\(\), null, null, null/);

// --- Harmony 实现：粘贴路径按源 elementId 读回 z，仅 STROKE 接线 ---
assert.match(persistence, /readOriginalClipboardSourceZIndex\(store: relationalStore\.RdbStore,\s*ref: PageElementRef\): Promise<string \| undefined>/);
assert.match(persistence, /decodeOperationId\(ref\.elementId\)/);
assert.match(persistence, /SELECT z_index FROM original_element_z_index WHERE element_timestamp = \?'\s*\+\s*' AND element_site_id = \? AND kind = \?/);
// 无 note/page/visible 约束：元素 op-id 全局唯一 → 跨页/跨笔记/cut(visible=0) 均可命中。
assert.doesNotMatch(persistence.match(/private async readOriginalClipboardSourceZIndex[\s\S]*?rows\.close\(\)/)[0], /visible|page_timestamp|note_id/);
assert.match(persistence, /rows\.goToNextRow\(\) \? undefined : zIndex/);
// 仅 STROKE 解析源 z；其余 kinds 保持 undefined → clientTime（原版 null 同约）。
assert.match(persistence, /ref\.kind === PageElementKind\.STROKE \?\s*await this\.readOriginalClipboardSourceZIndex\(store, ref\) : undefined/);
assert.match(persistence, /encodeOriginalLocalCreateInk\(page, stroke, sourceZIndex\)/);
assert.match(persistence, /encodeOriginalLocalCreateShape\(\s*page, shape, shapeMetadata\.averageForce\)/);
assert.match(persistence, /encodeOriginalLocalCreateTextBlock\(page, text\)/);
assert.match(persistence, /encodeOriginalLocalCreateImageBlock\(page, image\)/);
assert.match(persistence, /encodeOriginalLocalCreateMathBlock\(page, math\)/);
// clientTime 回退护栏改为逐元素判定（无源 z 时才检查 z-clock headroom）。
assert.match(persistence, /if \(sourceZIndex === undefined && maximumZIndex !== null &&\s*compareUnsignedLongDecimal\(maximumZIndex, identity\.clientTime\.toString\(\)\) > 0\)/);

// --- 编码器：shape/block 的 z 槽位按原版格式补齐（解码端已读 field 12/9），
// 但当前粘贴路径不接线（原版对应记录无 z 字段） ---
assert.match(inkEncoder, /zIndex === undefined \? 0 : 72/);
assert.match(shapeEncoder, /zIndex === undefined \? 0 : 28/);
assert.match(shapeEncoder, /builder\.uint64Decimal\(root \+ 28, zIndex\)/);
assert.match(blockEncoder, /fields\[9\] = zIndex === undefined \? 0 : 80/);
assert.match(blockEncoder, /fields\[9\] = zIndex === undefined \? 0 : 72/);
assert.match(blockEncoder, /fields\[9\] = zIndex === undefined \? 0 : 64/);
assert.match(blockEncoder, /local CREATE_BLOCK uint64 exceeds its field/);

// --- 功能仿真：源 z 解析语义（含 cut 源与缺席回退） ---
function sourceZ(rows, ref) {
  const hit = rows.filter(r => r.ts === ref.ts && r.site === ref.site && r.kind === ref.kind);
  if (hit.length !== 1) return undefined;
  return hit[0].z;
}
const strokeRef = { ts: 100, site: 7, kind: 0 };
assert.equal(sourceZ([{ ts: 100, site: 7, kind: 0, z: '999999', visible: 0 }], strokeRef), '999999');
assert.equal(sourceZ([{ ts: 100, site: 7, kind: 0, z: '42', visible: 1 }], strokeRef), '42');
assert.equal(sourceZ([], strokeRef), undefined);
assert.equal(sourceZ([{ ts: 100, site: 7, kind: 1, z: '5' }], strokeRef), undefined);
assert.equal(sourceZ([{ ts: 100, site: 7, kind: 0, z: '1' }, { ts: 100, site: 7, kind: 0, z: '2' }], strokeRef), undefined);

console.log('D04_ORIGINAL_PASTE_SOURCE_Z_INDEX_REPLAY_OK TOTAL=38 FAILED=0');
