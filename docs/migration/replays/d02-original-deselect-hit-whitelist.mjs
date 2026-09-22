// Phase 612 — deselectMode 点按命中测试白名单（xtc.a(jE, ftc.g) → fu1.e set 参）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   dl1.java:105-111 — deselectMode（ftc.h=true）按下：xtc.a(jE, ftc.g)，
//     命中测试白名单限定选中 id 集；otc 命中 → stc 移出选区。
//   fu1.java:270,303 — e(j,x09,set)：set 为白名单过滤
//     （set==null || set.contains(id)）；两程命中（精确 + ±5 容差）
//     均在白名单内。
//   fu1.java:445 — f() 区域命中同 set 参语义。
// 语义：未选中元素即使 z 序压在选中元素之上也不挡命中——点按穿透到
//   下方被选中元素并把它移出选区。
// Harmony 旧实现：topmostPageElementIdAt 在全集取最上层，再判
//   selected.has(hitId)——顶层未选中元素挡住下层被选中元素，deselect
//   点按落空（按覆盖层内外走 utc/qtc）。
// Harmony 新实现：hitOrderedElementIdAt/topmostPageElementIdAt 增
//   whitelist 参（fu1.e set 参等价），deselectTargetIdsAt 传 selected。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const VIEW = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const view = read(VIEW);

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 命中函数带 whitelist 参（fu1.e set 参等价） ---
const topIdx = view.indexOf('private topmostPageElementIdAt(');
check(topIdx > 0, 'topmostPageElementIdAt present');
const top = view.slice(topIdx, topIdx + 1100);
check(top.includes('whitelist: Set<string> | null = null'),
  'topmostPageElementIdAt takes an optional whitelist (fu1.e set param)');
check(top.includes('hitOrderedElementIdAt(ordered, point, 0, whitelist)') &&
  top.includes('hitOrderedElementIdAt(ordered, point, 5, whitelist)'),
  'both hit phases honour the whitelist (exact + tolerance)');
const hitIdx = view.indexOf('private hitOrderedElementIdAt(');
check(hitIdx > 0, 'hitOrderedElementIdAt present');
const hit = view.slice(hitIdx, hitIdx + 700);
check(hit.includes('whitelist !== null && !whitelist.has(element.data.id)'),
  'non-whitelisted elements are skipped in z-order scan');
check(hit.indexOf('whitelist.has') < hit.indexOf('let hit: boolean'),
  'whitelist skip precedes geometry tests');

// --- deselectTargetIdsAt 用 selected 白名单 ---
const dsIdx = view.indexOf('private deselectTargetIdsAt(');
check(dsIdx > 0, 'deselectTargetIdsAt present');
const ds = view.slice(dsIdx, dsIdx + 1600);
check(ds.indexOf('const selected: Set<string>') <
  ds.indexOf('topmostPageElementIdAt'),
  'selected set built before the hit test (xtc.a(jE, ftc.g) order)');
check(ds.includes('topmostPageElementIdAt(point, selected)'),
  'deselect hit test whitelisted to selected ids');
check(!ds.includes('topmostPageElementIdAt(point)'),
  'no unfiltered hit remains in the deselect path');
check(ds.includes('ftc.g') || ds.includes('xtc.a'),
  'original evidence reference present');

// --- 其余调用点保持默认（无白名单） ---
const calls = view.match(/topmostPageElementIdAt\([^)]*\)/g) || [];
const whitelisted = calls.filter((c) => c.includes('selected'));
check(whitelisted.length === 1,
  'only the deselect path passes a whitelist; others stay unfiltered');
check(calls.length > whitelisted.length,
  'unfiltered callers keep default behaviour (fu1.e set=null)');

console.log('D02_ORIGINAL_DESELECT_HIT_WHITELIST_OK TOTAL=' + n + ' FAILED=0');
