// Phase 615 — DUPLICATE 无数量门槛；>=2 门槛属 GROUP（dhb case4=GROUP）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   dsc.java:31-43 — 菜单枚举序：STYLE=0, COPY=1, CUT=2,
//     DUPLICATE=3, GROUP=4, UNGROUP=5。
//   dhb.java:17630-17636 — case2(CUT)/case3(DUPLICATE) 均派发
//     vsc 协程，仅变体索引不同（z4/z7 ? 1 : 0）。
//   vsc.java:45-80 — I==0 → lg2.d（cut：g+剪贴板写+删除）；
//     I==1 → lg2.b（g + fvb.a() 清选区 + e() 就地粘贴恢复）。
//     故 DUPLICATE = lg2.b = 复制+粘贴复合，对任意 ktc 生效——
//     itc 单元素、gtc 单组均可 DUPLICATE，无数量门槛。
//   dhb.java:17638-17654 — case4 = GROUP（dsc=4）：仅 ftc 且
//     A1=T1(ftc.q)+组id size>=2 才派发 kk9 建组协程并清选区。
//   lg2.java:171-191 — b() = g→cg2、fvb.a() 清选区、e() 应用负载
//     并恢复选区（粘贴即重选）。
// Harmony 对齐：DUPLICATE 菜单无条件 push（单元素/单组均可），
//   duplicateSelected 复制+粘贴、粘贴后重选（pasteClipboard
//   内 selectElementIds）；GROUP 由 selectionCanGroup =
//   authoringMembers>=2 把关（A1 等价集），本就与 case4 一致。
// 纠错说明：初版把 case4 的 >=2 门槛误挂到 DUPLICATE——case 号
//   即 dsc ordinal，case4=GROUP。已回退错误门槛。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const VIEW = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const OVL = 'note/src/main/ets/ui/components/SelectionOverlay.ets';
const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const view = read(VIEW);
const ovl = read(OVL);

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- DUPLICATE 菜单无条件（case3 无门槛：itc/gtc/ftc 均可） ---
const dupMenuIdx = ovl.indexOf("app.string.duplicate_note");
check(dupMenuIdx > 0, 'DUPLICATE menu item present');
const menuCtx = ovl.slice(dupMenuIdx - 400, dupMenuIdx);
check(!menuCtx.includes('canDuplicate'),
  'DUPLICATE is unconditional (dhb case3 has no count gate)');
check(ovl.includes('{ value: $r(\'app.string.duplicate_note\')') &&
  !ovl.includes('@Prop canDuplicate'),
  'no canDuplicate prop remains (gate reverted)');

// --- duplicateSelected 无门槛（lg2.b 对任意 ktc 生效） ---
const dupIdx = view.indexOf('private duplicateSelected(');
check(dupIdx > 0, 'duplicateSelected present');
const dup = view.slice(dupIdx, dupIdx + 1800);
check(!dup.includes('authoring.length < 2') && !dup.includes('selectionCanDuplicate'),
  'duplicateSelected has no top-level-count gate');
check(dup.includes('copySelectedToClipboard') && dup.includes('pasteClipboard(duplicateTarget)'),
  'duplicate = copy + paste composite (lg2.b: g + e() paste-apply)');
check(!view.includes('@State selectionCanDuplicate'),
  'selectionCanDuplicate state removed');
check(!view.includes('this.selectionCanDuplicate ='),
  'no duplicate gate computation remains');

// --- GROUP 仍持 >=2 门槛（case4 = GROUP 的正确归属） ---
check(view.includes('this.selectionCanGroup = groupMembers !== null && groupMembers.length >= 2'),
  'GROUP keeps authoringMembers>=2 (dhb case4 A1.size()>=2)');
const ovlGroupIdx = ovl.indexOf('if (this.canGroup)');
check(ovlGroupIdx > 0, 'GROUP menu item stays conditional (canGroup)');

// --- 粘贴后重选（lg2.b e() 恢复选区等价） ---
const pasteIdx = view.indexOf('private pasteClipboard(');
check(pasteIdx > 0, 'pasteClipboard present');
const paste = view.slice(pasteIdx, pasteIdx + 6000);
check(paste.includes('this.selectionTool.selectElementIds('),
  'paste re-selects pasted elements (lg2.b clear+reselect parity)');

console.log(`D02_ORIGINAL_DUPLICATE_GATE_OK TOTAL=${n} FAILED=0`);
