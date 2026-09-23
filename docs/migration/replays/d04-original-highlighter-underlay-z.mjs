// Phase 628 — 荧光笔 underlay z 带探针：原版 u5j.g（CreateInk 生产者）在
// zIndex 缺省且 InkTool==HIGHLIGHTER(u16=2) 时探测笔迹起点；起点落在所有
// 存活元素边界之外 → zIndex=999999 衬底带（低于 clientTime ~1.7e12 的正常内容），
// 起点落在既有内容之内 → 保留 null → 解码端回退 clientTime（顶层）。
// u5j.j（CreateShape 生产者）携带同一探针；g1f 生成的智能高亮矩形无条件钉 999999。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const u5j = fs.readFileSync(`${originalRoot}u5j.java`, 'utf8');
const g1f = fs.readFileSync(`${originalRoot}g1f.java`, 'utf8');
const dm2 = fs.readFileSync(`${originalRoot}dm2.java`, 'utf8');
const u16 = fs.readFileSync(`${originalRoot}u16.java`, 'utf8');
const persistence = fs.readFileSync('note/src/main/ets/data/StrokePersistence.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const encoder = fs.readFileSync('note/src/main/ets/data/OriginalCreateInkPayloadEncoder.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const inkOp = fs.readFileSync('note/src/main/ets/data/OriginalCreateInkOperation.ets', 'utf8')
  .replaceAll('\r\n', '\n');

// --- 原版证据：u5j.g 的 HIGHLIGHTER 门与 999999 衬底带 ---
assert.match(u16, /HIGHLIGHTER\(\(byte\) 2\)/);
assert.match(u5j, /u16Var2 != u16\.HIGHLIGHTER/);
const probeBlock = u5j.match(/if \(!z2\) \{\s*xgbVar3 = new xgb\(999999L\);\s*\}/);
assert.ok(probeBlock !== null, 'u5j.g keeps the !inside -> 999999 assignment');
// dm2 = CreateInk；xgb 形参落在 zIndex 字段（toString 的 zIndex=B() 读 long）。
assert.match(dm2, /zIndex=" \+ B\(\)/);
// u5j.j（CreateShape 生产者）携带同一探针；g1f 高亮矩形无条件钉 999999。
assert.match(u5j, /if \(!z4\) \{\s*xgbVar3 = new xgb\(999999L\);\s*\}/);
assert.match(g1f, /u16\.HIGHLIGHTER, null, hu1Var, 0\.0f, hu1Var2, new xgb\(999999L\)/);

// --- Harmony 实现：探针挂在本地 CreateInk 提交路径 ---
assert.match(persistence, /function originalHighlighterUnderlayZIndex\(stroke: StrokeElementData,\s*current: SearchSourceElement\[\]\): string \| undefined/);
assert.match(persistence, /if \(!stroke\.renderSpec\.isHighlighter \|\| stroke\.pathPoints\.length === 0\)/);
assert.match(persistence, /stroke\.pathPoints\[0\]\.position/);
assert.match(persistence, /transform\[0\] \* start\.x \+ transform\[1\] \* start\.y \+ transform\[2\]/);
assert.match(persistence, /transform\[3\] \* start\.x \+ transform\[4\] \* start\.y \+ transform\[5\]/);
assert.match(persistence, /decodePersistedElement\(element\.payload\)\.data\.bounds/);
assert.match(persistence, /x >= bounds\.left && x <= bounds\.right && y >= bounds\.top && y <= bounds\.bottom/);
assert.match(persistence, /return '999999'/);
assert.match(persistence, /encodeOriginalLocalCreateInk\(\s*page, stroke, originalHighlighterUnderlayZIndex\(stroke, current\)\)/);

// --- 边界：非荧光笔/显式 zIndex 路径不受影响 ---
// 局部擦除残余段保留显式 '1'/sourceZIndex；写路径只有 draw-commit 走探针。
assert.match(persistence, /encodeOriginalLocalCreateInk\(page, remnant, '1'\)/);
assert.match(persistence, /encodeOriginalLocalCreateInk\(\s*page, stroke, sourceZIndex\)/);

// --- 解码端：zIndex 缺席时回退 clientTime（原版 null→clientTime 同约） ---
assert.match(inkOp, /decodeOriginalCreateInk\(operation\.rawOperation, operation\.clientTime\)/);
assert.match(encoder, /zIndex === undefined \? 0 : 72/);

// --- 功能仿真：探针语义复刻 ---
function underlayZIndex(stroke, current) {
  if (!stroke.isHighlighter || stroke.pathPoints.length === 0) {
    return undefined;
  }
  const t = stroke.transform;
  const start = stroke.pathPoints[0];
  const x = t[0] * start.x + t[1] * start.y + t[2];
  const y = t[3] * start.x + t[4] * start.y + t[5];
  for (const bounds of current) {
    if (x >= bounds.left && x <= bounds.right && y >= bounds.top && y <= bounds.bottom) {
      return undefined;
    }
  }
  return '999999';
}
const IDENTITY = [1, 0, 0, 0, 1, 0, 0, 0, 1];
const hi = (pts, t = IDENTITY) => ({ isHighlighter: true, pathPoints: pts, transform: t });
const pen = (pts) => ({ isHighlighter: false, pathPoints: pts, transform: IDENTITY });
const inkBounds = { left: 100, top: 100, right: 300, bottom: 300 };

// 起点在空画布（无元素）→ 999999。
assert.equal(underlayZIndex(hi([{ x: 500, y: 500 }]), []), '999999');
// 起点在既有内容之外（元素存在但不含起点）→ 999999。
assert.equal(underlayZIndex(hi([{ x: 500, y: 500 }]), [inkBounds]), '999999');
// 起点落在既有内容之内（边界含端点，闭区间）→ undefined（clientTime 顶层）。
assert.equal(underlayZIndex(hi([{ x: 200, y: 200 }]), [inkBounds]), undefined);
assert.equal(underlayZIndex(hi([{ x: 100, y: 300 }]), [inkBounds]), undefined);
// 非荧光笔 → 恒 undefined。
assert.equal(underlayZIndex(pen([{ x: 500, y: 500 }]), []), undefined);
// 空路径 → undefined（编码端另有 pathPoints 非空校验）。
assert.equal(underlayZIndex(hi([]), []), undefined);
// 非单位变换：起点按 transform 投影后再探测。
const moved = [1, 0, 50, 0, 1, 50, 0, 0, 1];
assert.equal(underlayZIndex(hi([{ x: 100, y: 100 }], moved), [inkBounds]), undefined);
assert.equal(underlayZIndex(hi([{ x: 400, y: 400 }], moved), [inkBounds]), '999999');

console.log('D04_ORIGINAL_HIGHLIGHTER_UNDERLAY_Z_REPLAY_OK TOTAL=29 FAILED=0');
