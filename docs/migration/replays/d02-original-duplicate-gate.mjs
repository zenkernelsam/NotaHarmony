// Phase 615 — DUPLICATE 菜单门槛：顶层项 >=2（dhb case4 A1.size()>=2）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   dhb.java:17638-17654（case4）— DUPLICATE 仅当 ktcVar instanceof ftc
//     时执行：arrayListA1 = T1(ftcVar.q) + ftcVar.m 各组 id，
//     要求 size() >= 2 才派发 kk9 协程并 fvbVar.a() 清选区；否则静默。
//     itc（单元素）/gtc（单组）根本不进 case4——单选 DUPLICATE 是死操作。
//   gtc.java:90-93 — f() 返回 qw3 空集：组成员不计入 ftc.q 扁平集，
//     故 A1 = 「未入组散件 id + 选中组 id」= 顶层项数。
// Harmony 旧实现：SelectionOverlay 无条件 push DUPLICATE，
//   duplicateSelected 也无门槛——单元素/单组可复制，原版不可。
// Harmony 新实现：selectionCanDuplicate = authoringMembers>=2
//   （resolveOriginalGroupAuthoringMembers 即 T1(ftc.q)+组id 等价集），
//   菜单项条件 push；duplicateSelected 同门槛 fail-closed 兜底。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const VIEW = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const OVL = 'note/src/main/ets/ui/components/SelectionOverlay.ets';
const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const view = read(VIEW);
const ovl = read(OVL);

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- @State + 门槛计算（复用 authoringMembers = ftc.q+m 等价集） ---
check(view.includes('@State selectionCanDuplicate: boolean = false'),
  'selectionCanDuplicate state exists');
check(view.includes('this.selectionCanDuplicate = groupMembers !== null && groupMembers.length >= 2'),
  'gate = authoring members >= 2 (dhb case4 A1.size()>=2)');
const gateIdx = view.indexOf('this.selectionCanDuplicate =');
const gateCtx = view.slice(gateIdx - 600, gateIdx + 100);
check(gateCtx.includes('resolveOriginalGroupAuthoringMembers('),
  'gate reuses resolveOriginalGroupAuthoringMembers (ungrouped leaves + group ids)');

// --- duplicateSelected fail-closed 兜底（itc/gtc 不进 case4 等价） ---
const dupIdx = view.indexOf('private duplicateSelected(');
check(dupIdx > 0, 'duplicateSelected present');
const dup = view.slice(dupIdx, dupIdx + 1200);
check(dup.includes('resolveOriginalGroupAuthoringMembers(') &&
  dup.includes('authoring === null || authoring.length < 2'),
  'duplicateSelected no-ops below 2 top-level items (ftc-only + >=2 gate)');
check(dup.indexOf('authoring.length < 2') < dup.indexOf('copySelectedToClipboard'),
  'gate runs before the clipboard write (no side effects on dead dispatch)');

// --- 菜单项条件 push ---
check(ovl.includes('@Prop canDuplicate: boolean = false'),
  'SelectionOverlay takes canDuplicate prop');
const dupMenuIdx = ovl.indexOf("app.string.duplicate_note");
check(dupMenuIdx > 0, 'DUPLICATE menu item present');
const menuCtx = ovl.slice(dupMenuIdx - 500, dupMenuIdx + 200);
check(menuCtx.includes('if (this.canDuplicate)'),
  'DUPLICATE menu item is conditional on canDuplicate');
check(view.includes('canDuplicate: this.selectionCanDuplicate'),
  'overlay wiring passes selectionCanDuplicate');

// --- CUT/COPY 不受门槛影响（dhb case1/2 无 >=2 要求） ---
const cutIdx = ovl.indexOf("app.string.cut");
const cutCtx = ovl.slice(cutIdx - 400, cutIdx + 100);
check(!cutCtx.includes('canDuplicate'), 'CUT remains unconditional');
check(!view.includes('selectionCanDuplicate = groupMembers !== null && groupMembers.length >= 2 &&'),
  'duplicate gate does not inherit canGroup canonical-id condition');

console.log(`D02_ORIGINAL_DUPLICATE_GATE_OK TOTAL=${n} FAILED=0`);
