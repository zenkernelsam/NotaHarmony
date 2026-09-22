// Phase 610 — 复制/剪切剔除 positionLocked 元素（lg2.g → jrh.a/ac4.Q）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   lg2.java:107-123 — g(x09,ktc)：ac4.Q(POSITION_LOCKED，PRODUCTION 默认开)
//     时对 ktc.h() 以 jrh.a(be5) 过滤得 set；后续边界 a()、ops u5j.c、
//     组负载 arrayList5 全部基于过滤后的 set。
//   lg2.java:153-155 — c() 递归把可解析组员放入 arrayList3，组员不过滤
//     （与 fu1.c 组扩展不二次过滤一致）。
//   lg2.java:168 — gg2(cg2, set)：返回负载携 set 字段，供剪切删除用。
//   dhb.java:17615-17629 — case1 COPY：g() 非空 → c.a=cg2 + fvb.a() 清空；
//     g() 为空（全锁/无界）→ 不写剪贴板也不清选区。
//   dhb.java:17638-17652 — case4 DUPLICATE：直接用 ftc.q/m 原始 id 列表，
//     不经 jrh.a——DUPLICATE 不过滤。
//   jrh.java:13-22 — oy0 块→t()；m4d 形状→cih.a&&t()；s06 笔迹→false。
// Harmony：COPY/CUT 先经 clipboardSelectionWithoutLocked 过滤四类块，
//   笔迹不过滤；CUT 的移除列表同用过滤集；DUPLICATE 保持未过滤；
//   全锁选区 → prepareSelectedClipboard 空集返回 null → 不清选区。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const VIEW = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const view = read(VIEW);

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 接口与助手存在 ---
check(view.includes('interface ClipboardSelectionIdSet'),
  'ClipboardSelectionIdSet result interface declared');
const helperIdx = view.indexOf('private clipboardSelectionWithoutLocked(');
check(helperIdx > 0, 'clipboardSelectionWithoutLocked helper exists');
const helper = view.slice(helperIdx, view.indexOf('private prepareSelectedClipboard('));
check(helper.includes('shape.positionLocked === true'),
  'locked shapes collected into lockedIds (n5d.t parity)');
check(helper.includes('textBlock.positionLocked === true'),
  'locked text blocks collected (oy0.t parity)');
check(helper.includes('image.positionLocked === true'),
  'locked images collected (oy0.t parity)');
check(helper.includes('math.positionLocked === true'),
  'locked math blocks collected (oy0.t parity)');
check(!helper.includes('completedStrokes'),
  'strokes never enter lockedIds (jrh.a(s06)=false)');
check(helper.includes('strokeIds: ids'),
  'stroke id list passes through unfiltered');
check(helper.indexOf('shapeIds.filter') > helper.indexOf('lockedIds'),
  'shape ids filtered against lockedIds');

// --- CUT：过滤后再复制+删除同一集合 ---
const cutIdx = view.indexOf('if (action === SelectionMenuAction.CUT) {');
check(cutIdx > 0, 'CUT branch present');
const cut = view.slice(cutIdx, cutIdx + 1400);
check(cut.includes('clipboardSelectionWithoutLocked'),
  'CUT filters selection ids before clipboard preparation');
check(cut.indexOf('clipboardSelectionWithoutLocked') <
  cut.indexOf('prepareSelectedClipboard'),
  'lock filter precedes prepareSelectedClipboard (lg2.g order)');
check(cut.includes('ids = kept.strokeIds') && cut.includes('shapeIds = kept.shapeIds'),
  'CUT removal lists reuse the filtered id set (gg2.set delete parity)');

// --- COPY：过滤后写剪贴板，成功才清选区（dhb case1） ---
const copyIdx = view.indexOf('} else if (action === SelectionMenuAction.COPY) {');
check(copyIdx > 0, 'COPY action branch present');
const copy = view.slice(copyIdx, copyIdx + 1200);
check(copy.includes('clipboardSelectionWithoutLocked'),
  'COPY filters locked ids (dhb case1 → lg2.g parity)');
check(copy.indexOf('copySelectedToClipboard') < copy.indexOf('clearSelectionWithRegisterReset'),
  'selection clears only after a successful clipboard write (fvb.a parity)');

// --- DUPLICATE 不过滤（dhb case4 用 ftc.q/m 原始列表） ---
const dupIdx = view.indexOf('private duplicateSelected(');
check(dupIdx > 0, 'duplicateSelected present');
const dup = view.slice(dupIdx, dupIdx + 1200);
check(!dup.includes('clipboardSelectionWithoutLocked'),
  'DUPLICATE does not lock-filter (dhb case4 raw ftc.q/m parity)');

// --- 空集短路：全锁选区 → null → 不写剪贴板/不清选区 ---
const prepIdx = view.indexOf('private prepareSelectedClipboard(');
check(prepIdx > 0, 'prepareSelectedClipboard present');
const prep = view.slice(prepIdx, prepIdx + 4000);
check(prep.includes('selectedCount === 0'),
  'empty filtered set returns null (lg2.g → null: no write, no clear)');

console.log('D02_ORIGINAL_CLIPBOARD_LOCK_FILTER_OK TOTAL=' + n + ' FAILED=0');
