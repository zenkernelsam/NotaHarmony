// Phase 742 — 原版 Zoom View 旗标判定更正（ADR-0690 更正 ADR-0644 ZOOM 项）。
// 原版证据（decompiled_1.0.3/sources/defpackage + resources）：
//   ac4.java     e0 = ac4("ZOOM_VIEW",19,zb4.L,ztb.c,null) —— PRODUCTION 级旗标。
//   ztb.java     extends lrb，键 "androidZoomView"。
//   zb4.java     OFF(0)/DEBUG_ONLY(1)/INTERNAL_USERS_ONLY(2)/PRODUCTION(3)；
//                lc4 静态 g = zb4.L。
//   lc4.java     a()：PRODUCTION(ordinal 3) 分支读 trb.e(ac4Var.J) 远程值；
//                w51.a()=ra(8) JUnit 探测（生产恒 false）；b()=g<=INTERNAL 恒 false。
//   trb.java     e(orb) → oh4.h.b(str) → lrb 分支 sh4.a() 返回 boolean。
//   core_remoteconfig__remote_config_defaults.xml  androidZoomView=true；
//                同路径 androidNoteTapeTool=true（REVIEW/tape 默认可见已移植）。
//   a6f.java     U=ZOOM(12)；s01.a0：RULER(T) 恒剔除、ZOOM(U) 需 lc4.a(e0)、
//                REVIEW(S) 需 lc4.a(t0)。
//   x82.java     case 12 → ui_tools__zoom="Zoom"。
//   ww2.java     控制条：back/forward/return(zoom_return)/close 四键。
//   g0j.java     zoom_advance_tab 把手 + zq4 拖动 move 语义。
//   strings.xml  feature_note_wetink_ui__zoom_view_* 六个无障碍标签；
//                ui_permissions__* 六个权限 rationale 串（同族尾登记）。
// 更正结论：ZOOM 为原版默认开启、Harmony 未移植的延迟移植缺口
// （port-deferred），非旗标对等；POINTER/RULER/view-only 维持 ADR-0644。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const ac4 = fs.readFileSync(`${originalRoot}sources/defpackage/ac4.java`, 'utf8');
const ztb = fs.readFileSync(`${originalRoot}sources/defpackage/ztb.java`, 'utf8');
const zb4 = fs.readFileSync(`${originalRoot}sources/defpackage/zb4.java`, 'utf8');
const lc4 = fs.readFileSync(`${originalRoot}sources/defpackage/lc4.java`, 'utf8');
const trb = fs.readFileSync(`${originalRoot}sources/defpackage/trb.java`, 'utf8');
const a6f = fs.readFileSync(`${originalRoot}sources/defpackage/a6f.java`, 'utf8');
const s01 = fs.readFileSync(`${originalRoot}sources/defpackage/s01.java`, 'utf8');
const x82 = fs.readFileSync(`${originalRoot}sources/defpackage/x82.java`, 'utf8');
const ww2 = fs.readFileSync(`${originalRoot}sources/defpackage/ww2.java`, 'utf8');
const g0j = fs.readFileSync(`${originalRoot}sources/defpackage/g0j.java`, 'utf8');
const rcDefaults = fs.readFileSync(
  `${originalRoot}resources/res/xml/core_remoteconfig__remote_config_defaults.xml`, 'utf8');
const stringsXml = fs.readFileSync(`${originalRoot}resources/res/values/strings.xml`, 'utf8');

const brush = fs.readFileSync('note/src/main/ets/core/model/BrushTypes.ets', 'utf8');
const vm = fs.readFileSync('note/src/main/ets/ui/editor/EditorViewModel.ets', 'utf8');
const toolbar = fs.readFileSync('note/src/main/ets/ui/editor/EditorToolbar.ets', 'utf8');
const adr0644 = fs.readFileSync(
  'docs/migration/adr/ADR-0644-original-pointer-zoom-presence-failclosed.md', 'utf8');
const adr0690 = fs.readFileSync(
  'docs/migration/adr/ADR-0690-original-zoom-view-flag-correction.md', 'utf8');
const evidence = fs.readFileSync(
  'docs/migration/evidence/original-zoom-view-flag-correction-jadx-2026-09-25.md', 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 旗标定义链 ---
check(ac4.includes('"ZOOM_VIEW"'), 'ac4 定义 ZOOM_VIEW');
check(/new ac4\("ZOOM_VIEW", 19, zb4Var, ztb\.c/.test(ac4), 'ac4.e0 第三参 zb4 第四参 ztb.c');
check(ztb.includes('extends lrb') && ztb.includes('"androidZoomView"'),
  'ztb.c = lrb("androidZoomView")');
check(zb4.includes('"OFF", 0') && zb4.includes('"DEBUG_ONLY", 1') &&
  zb4.includes('"INTERNAL_USERS_ONLY", 2') && zb4.includes('"PRODUCTION", 3'),
  'zb4 枚举序 OFF/DEBUG_ONLY/INTERNAL/PRODUCTION');
check(lc4.includes('g = zb4.L'), 'lc4 构建上下文 g = PRODUCTION');
check(lc4.includes('trb.e(ac4Var.J)'), 'lc4 PRODUCTION 分支读 trb.e 远程值');
check(trb.includes('oh4Var.h.b(str)') && trb.includes('sh4VarB.a()'),
  'trb.e → oh4.h.b → sh4.a() 布尔');

// --- 打包默认值 ---
const rcBlock = (key) => {
  const m = rcDefaults.match(new RegExp(`${key}[^]*?<value>(\\w+)`, 'm'));
  return m ? m[1] : null;
};
check(rcBlock('androidZoomView') === 'true', 'androidZoomView 打包默认 true');
check(rcBlock('androidNoteTapeTool') === 'true', 'androidNoteTapeTool 打包默认 true（对照）');

// --- 工具枚举与过滤门 ---
check(/new a6f\("ZOOM", 12\)/.test(a6f), 'a6f.U = ZOOM(12)');
check(/new a6f\("RULER", 11\)/.test(a6f), 'a6f.T = RULER(11)');
check(/new a6f\("REVIEW", 10\)/.test(a6f), 'a6f.S = REVIEW(10)');
check(s01.includes('lc4.a(ac4.e0)') && s01.includes('lc4.a(ac4.t0)'),
  's01.a0：ZOOM 需 e0 旗标、REVIEW 需 t0 旗标');
check(s01.includes('r5fVar.g() != a6f.T'), 's01.a0：RULER 无条件剔除');
check(x82.includes('ui_tools__zoom'), 'x82 case12 → ui_tools__zoom 标签');

// --- Zoom View 表面 ---
check(ww2.includes('zoom_view_back_description') &&
  ww2.includes('zoom_view_forward_description') &&
  ww2.includes('zoom_view_return_description') &&
  ww2.includes('zoom_view_close_description'), 'ww2 控制条四键标签');
check(ww2.includes('ui_designsystem__zoom_return'), 'ww2 return 键用 zoom_return 图标');
check(g0j.includes('zoom_view_advance_region_description') &&
  g0j.includes('zoom_advance_tab'), 'g0j 前移区把手');
check(g0j.includes('zq4'), 'g0j 拖动把手 zq4（Move Zoom View）');
check(stringsXml.includes('zoom_view_move_description'), 'strings 含 move 标签');
check(stringsXml.includes('ui_permissions__camera_access_required') &&
  stringsXml.includes('ui_permissions__microphone_access_required'),
  'strings 含 ui_permissions 权限串');

// --- Harmony 现状断言（absence + 更正登记）---
check(!toolbar.includes('zoom_view') && !vm.includes('zoom_view'),
  'Harmony 无 zoom_view 实现');
check(brush.includes('ADR-0644') || vm.includes('ADR-0644'),
  '留位注释仍指 ADR-0644（更正由 0690 承接）');
check(adr0644.includes('ADR-0690'), 'ADR-0644 已加更正指引');
check(adr0690.includes('androidZoomView') && adr0690.includes('延迟移植缺口'),
  'ADR-0690 登记默认开启 + 延迟移植缺口');
check(evidence.includes('androidZoomView') && evidence.includes('s01.a0'),
  '证据文档含旗标链与过滤门');

console.log(`D02_ORIGINAL_ZOOM_VIEW_FLAG_CORRECTION_REPLAY_OK TOTAL=${n} FAILED=0`);
