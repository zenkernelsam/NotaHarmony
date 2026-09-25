// Phase 677 — 原版 POINTER（presence 光标）/ view-only 门控：fail-closed
// 登记。ZOOM 项已于 Phase 747 移植（ADR-0690 更正旗标默认开，
// ADR-0695 落地）——本夹具仅继续钉 POINTER/RULER 边界与
// ZOOM 的副托盘 index 2 落位。
// 原版证据（decompiled_1.0.3/sources/defpackage）：
//   a6f.java     13 工具枚举：POINTER(8)/ZOOM(12) 为缺口成员。
//   rz1.java     r() 次托盘：u5f(10,1,a6f.Q,0,null)=POINTER(tool_id10)、
//     LASER(1)、ZOOM(2)、REVIEW(3)、RULER(4)。
//   s01.java     a0()：RULER 无条件剔除、ZOOM 仅 lc4.a(ac4.e0)、
//     REVIEW 仅 ac4.t0；X(z,tool)=!z||tool==Q —— view-only 全禁用
//     仅放行 POINTER；b0(list,z) view-only 剔除 POINTER。
//   c59.java     ac4.b0(VIEW_ONLY) 评估每笔记 view-only 状态流。
//   dg9.java     case 0：ti9.V 编辑许可变 false → i8f.i(a6f.Q)
//     自动切 POINTER。
//   ti9.java     l0={POINTER} 瞬态工具集；p() 放行条件引用 l0。
//   wda/zda/aea/gm/mzc/l96：presence 协议与远端光标渲染
//     （presence_pen/highlighter/cursor 图标）；zda.f 默认
//     u76.POINTER。
//   sva/tzc.java ac4.c0(MULTIPLAYER_PRESENCE) 门控会话层。
//   w4g/y5f      POINTER 无宽度档、无 e31 视觉配置。
//   ac4.java     e0=ZOOM_VIEW(zb4.L 远程通道, ztb.c=androidZoomView)。
// Harmony 判定：POINTER 属服务端协作域（presence 光标）→ fail-closed；
// RULER 原版 s01.a0 无条件隐藏；ZOOM 已移植（Phase 747）——
// 次托盘 index0/4 留空、index 2 由 zoom 占据。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const a6f = fs.readFileSync(`${originalRoot}sources/defpackage/a6f.java`, 'utf8');
const rz1 = fs.readFileSync(`${originalRoot}sources/defpackage/rz1.java`, 'utf8');
const s01 = fs.readFileSync(`${originalRoot}sources/defpackage/s01.java`, 'utf8');
const c59 = fs.readFileSync(`${originalRoot}sources/defpackage/c59.java`, 'utf8');
const dg9 = fs.readFileSync(`${originalRoot}sources/defpackage/dg9.java`, 'utf8');
const ti9 = fs.readFileSync(`${originalRoot}sources/defpackage/ti9.java`, 'utf8');
const zda = fs.readFileSync(`${originalRoot}sources/defpackage/zda.java`, 'utf8');
const l96 = fs.readFileSync(`${originalRoot}sources/defpackage/l96.java`, 'utf8');
const sva = fs.readFileSync(`${originalRoot}sources/defpackage/sva.java`, 'utf8');
const tzc = fs.readFileSync(`${originalRoot}sources/defpackage/tzc.java`, 'utf8');
const ac4 = fs.readFileSync(`${originalRoot}sources/defpackage/ac4.java`, 'utf8');
const x82 = fs.readFileSync(`${originalRoot}sources/defpackage/x82.java`, 'utf8');
const w4g = fs.readFileSync(`${originalRoot}sources/defpackage/w4g.java`, 'utf8');
const stringsXml = fs.readFileSync(`${originalRoot}resources/res/values/strings.xml`, 'utf8');

const brush = fs.readFileSync('note/src/main/ets/core/model/BrushTypes.ets', 'utf8');
const vm = fs.readFileSync('note/src/main/ets/ui/editor/EditorViewModel.ets', 'utf8');
const toolbar = fs.readFileSync('note/src/main/ets/ui/editor/EditorToolbar.ets', 'utf8');
const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 原版证据钉：枚举与种子 ---
check(a6f.includes('new a6f("POINTER", 8)') && a6f.includes('new a6f("ZOOM", 12)'),
  'a6f POINTER/ZOOM enum');
check(/u5f\(10, 1, a6f\.Q, 0, null/.test(rz1), 'rz1 POINTER tool_id10 tray1 idx0');
check(/u5f\(0, 1, a6f\.U, 2, null/.test(rz1), 'rz1 ZOOM tray1 idx2');
check(/u5f\(0, 1, a6f\.T, 4, null/.test(rz1), 'rz1 RULER tray1 idx4');

// --- 原版证据钉：门控 ---
check(/a6f\.U \|\| zA\)/.test(s01) || s01.includes('!= a6f.U || zA'),
  's01.a0 ZOOM flag gate (ac4.e0)');
check(/!= a6f\.S \|\| zA2/.test(s01), 's01.a0 REVIEW flag gate (ac4.t0)');
check(/!= a6f\.T/.test(s01), 's01.a0 RULER unconditional hide');
check(/!z \|\| r5fVar\.g\(\) == a6f\.Q/.test(s01), 's01.X view-only → POINTER only');
check(/r5f\) obj\)\.g\(\) != a6f\.Q/.test(s01), 's01.b0 view-only drops POINTER');
check(c59.includes('ac4.b0'), 'c59 VIEW_ONLY flag eval');
check(dg9.includes('i8fVar.i(a6f.Q'), 'dg9 auto-activates POINTER');
check(ti9.includes('l0 = ys2.P(a6f.Q)'), 'ti9.l0 transient set');
check(ac4.includes('"ZOOM_VIEW", 19'), 'ac4.e0 = ZOOM_VIEW');
check(ac4.includes('"VIEW_ONLY", 16'), 'ac4.b0 = VIEW_ONLY');
check(ac4.includes('"MULTIPLAYER_PRESENCE", 17'), 'ac4.c0 = MULTIPLAYER_PRESENCE');

// --- 原版证据钉：presence 协议层 ---
check(zda.includes('u76.POINTER'), 'zda default presence tool POINTER');
check(l96.includes('ui_designsystem__presence_cursor'), 'l96 remote cursor icon');
check(l96.includes('ui_designsystem__presence_pen'), 'l96 remote pen icon');
check(sva.includes('lc4.a(ac4.c0)'), 'sva presence gate');
check(tzc.includes('lc4.a(ac4.c0)'), 'tzc session presence gate');
check(/a6f\.Q, new Float\[0\]/.test(w4g), 'w4g POINTER no width well');
check(stringsXml.includes('<string name="ui_tools__pointer">Pointer</string>'),
  'original Pointer label');
check(stringsXml.includes('<string name="ui_tools__zoom">Zoom</string>'),
  'original Zoom label');

// --- Harmony fail-closed 钉（POINTER/RULER）+ ZOOM 移植钉（Phase 747）---
check(!/POINTER\s*=\s*\d/.test(brush), 'no ToolType.POINTER');
check(/ZOOM = 9/.test(brush), 'ToolType.ZOOM=9 ported (Phase 747)');
check(brush.includes('ADR-0644'), 'BrushTypes comment cites ADR-0644');
check(brush.includes('presence'), 'BrushTypes comment explains presence domain');
check(brush.includes('ADR-0690'), 'BrushTypes comment cites ADR-0690 correction');
check(vm.includes('ADR-0644'), 'EditorViewModel comment cites ADR-0644');
// 次托盘序：POINTER(0) 留空、LASER(1)、ZOOM(2)、REVIEW(3)、RULER(4) 留空
check(/'laser', ownerId, ToolType\.LASER, 1,/.test(vm), 'laser keeps index 1');
check(/'zoom', ownerId, ToolType\.ZOOM, 2,/.test(vm), 'zoom seeded index 2');
check(/'tape', ownerId, ToolType\.REVIEW, 3,/.test(vm), 'tape keeps index 3');
check(!/createState\('pointer'/.test(vm), 'no pointer tool state');
check(!toolbar.includes('ui_tools__pointer') && !toolbar.includes('pointer_tool'),
  'no pointer button in toolbar');
check(!canvas.includes('presence_cursor'), 'no presence cursor rendering');

console.log(`TOTAL=${n}`);
