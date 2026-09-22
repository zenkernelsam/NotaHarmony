// Phase 614 — 复制/剪切对含锁定成员的 Group 弃组不散件（lg2.c 递归解析）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   lg2.java:107-168（g）— 复制集 = jrh.a 过滤后的 h() 扁平 id 集 +
//     arrayList3（解析成功的 Group id）；iterableL0 为选中 cqc 组列表，
//     逐组调 c() 解析；arrayList5 只保留解析成功的组 → 粘贴恢复组。
//   lg2.java:51-105（c）— 递归：set.contains(id)||resolved → true；
//     failed → false；tl7.v(id) 得 h85 组 → 遍历 M() 成员，任一成员
//     递归失败则 z=false → failed.add(id)；全过 → resolved+out.add(id)。
//     即「Group 成员闭包必须全在过滤后集合内」，一个锁定成员使整组弃件，
//     但未锁定成员仍作为散件保留在 set 中复制/删除。
//   itc.java:19,35,45 — ktc 三集：c()=空、f()={元素}、h()={元素}；
//   gtc.java:56,90,105 — c()=成员集、f()=qw3 空、h()=成员集；
//   故 lg2.g 的 h() 过滤天然覆盖组成员（成员 id 在扁平集内）。
// Harmony 旧实现：clipboardSelectionWithoutLocked 只过滤扁平 id，
//   selectedGroupIds 原样进 prepareCopy；copyOriginalGroupGraph 对任一
//   成员不在 copiedLeafIds 的组返回 null → prepareCopy 整个返回 null
//   → COPY 不写剪贴板、CUT 什么都不删（整单失败）。
// Harmony 新实现：copyResolvableGroupIds 按 lg2.c 语义递归解析选中组，
//   成员闭包不全在 kept 集内的组从 groupIds 剔除——散件照常复制，
//   弃组不随负载（粘贴后不成组），整单不再失败。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const VIEW = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const view = read(VIEW);

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- ClipboardSelectionIdSet 携带 groupIds ---
const ifaceIdx = view.indexOf('interface ClipboardSelectionIdSet');
check(ifaceIdx > 0, 'ClipboardSelectionIdSet present');
const iface = view.slice(ifaceIdx, ifaceIdx + 400);
check(iface.includes('groupIds: string[]'),
  'selection id set carries resolved groupIds');

// --- clipboardSelectionWithoutLocked 接收并解析组 ---
const fnIdx = view.indexOf('private clipboardSelectionWithoutLocked(');
check(fnIdx > 0, 'clipboardSelectionWithoutLocked present');
const fn = view.slice(fnIdx, fnIdx + 1600);
check(fn.includes("groupIds: string[] = []"),
  'filter takes the selected group ids');
check(fn.includes('this.copyResolvableGroupIds(groupIds, kept)'),
  'group ids are resolved against the kept leaf set');

// --- copyResolvableGroupIds = lg2.c 递归语义 ---
const resIdx = view.indexOf('private copyResolvableGroupIds(');
check(resIdx > 0, 'copyResolvableGroupIds present');
const res = view.slice(resIdx, resIdx + 2200);
check(res.includes('keptIds.has(id)') && res.includes('resolved.has(id)'),
  'kept leaf or resolved group satisfies membership (lg2.c base case)');
check(res.includes('failed.has(id)') && res.includes('visiting.has(id)'),
  'failed/visiting guard rejects unresolvable and cyclic members');
check(res.includes('groupById.get(id)') &&
  res.includes('group.members.length === 0'),
  'missing group row or empty member list fails resolution (tl7.v null / empty M())');
check(res.includes('for (const member of group.members)') &&
  res.includes('!resolve(member)'),
  'every member must resolve recursively (h85.M() closure)');
check(res.includes('if (resolve(groupId))') && res.includes('groupIds.push(groupId)'),
  'only fully-resolved groups stay in the copy payload (arrayList5 parity)');

// --- COPY/CUT 消费 kept.groupIds ---
check(view.includes('this.clipboardSelectionWithoutLocked(\n        state.selectedStrokeIds, state.selectedShapeIds, state.selectedTextBlockIds,\n        state.selectedImageIds, state.selectedMathIds, state.selectedGroupIds)'),
  'COPY passes the selected group ids into the filter');
check(view.includes('kept.imageIds, kept.mathIds, kept.groupIds))'),
  'COPY writes the resolved group ids to the clipboard');
check(view.includes('ids, shapeIds, textIds, imageIds, mathIds, kept.groupIds)'),
  'CUT prepares the clipboard with the resolved group ids');
check(!view.includes('kept.imageIds, kept.mathIds, state.selectedGroupIds))') &&
  !view.includes('mathIds, state.selectedGroupIds);\n      }\n      if (action === SelectionMenuAction.CUT'),
  'no copy/cut path still forwards the unfiltered selectedGroupIds');

// --- DUPLICATE 仍走未过滤原集（dhb case4 ftc.q/m 不等 lg2.g） ---
const dupIdx = view.indexOf('SelectionMenuAction.DUPLICATE');
check(dupIdx > 0, 'DUPLICATE branch present');
const dupEnd = view.indexOf('SelectionMenuAction.FLIP_H', dupIdx);
const dup = view.slice(dupIdx, dupEnd > 0 ? dupEnd : dupIdx + 600);
check(dup.includes('this.duplicateSelected(state.selectedStrokeIds') &&
  dup.includes('state.selectedGroupIds') && !dup.includes('clipboardSelectionWithoutLocked'),
  'DUPLICATE uses raw ids incl. unfiltered groupIds (dhb case4 ftc.q/m, not lg2.g)');

console.log(`D02_ORIGINAL_CLIPBOARD_GROUP_RESOLVE_OK TOTAL=${n} FAILED=0`);
