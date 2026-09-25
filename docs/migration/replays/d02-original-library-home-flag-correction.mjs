// Phase 743 — 原版 LIBRARY_HOME 旗标判定更正 + 远程默认值全量扫描收官
// （ADR-0691 更正 ADR-0655；接续 ADR-0690 同类更正）。
// 原版证据（decompiled_1.0.3）：
//   ac4.java:182  F0 = ac4("LIBRARY_HOME",47,zb4.L,tsb.c) —— PRODUCTION 级。
//   tsb.java      extends lrb，键 "androidLibraryHome"。
//   rc defaults   androidLibraryHome=true（打包默认）。
//   ajh.java:335  lc4.a(ac4.F0) 为真 → 导航列表插入 feature_library__home。
//   va7.java:30 / wa7.java:118  同旗标门控分区图标（tnc.a 选中态）。
//   ksh.java      Home 组合族：home_record_lecture/home_take_notes/
//                 home_favorite_notes/home_recent_notes/home_study_up_next。
// 扫描收官：51 键默认表分类完毕；true 默认旗标除 ZOOM_VIEW(ADR-0690)
// 与 LIBRARY_HOME(本 ADR) 外，均为已移植功能或有效 fail-closed 边界；
// ENTITY_GROUPS(ac4.V→uw2/vo2/xtc fu1.c 组扩展) 与
// SHAPE_EDIT_SNAPPING(ac4.Y→avc 形状会话) 默认 true 且已移植
// （OriginalGroupSelection/OriginalSnapGuides）。
// Harmony 现状：经典 Library 无 Home 分区 → 延迟移植缺口登记。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const ac4 = fs.readFileSync(`${originalRoot}sources/defpackage/ac4.java`, 'utf8');
const tsb = fs.readFileSync(`${originalRoot}sources/defpackage/tsb.java`, 'utf8');
const ajh = fs.readFileSync(`${originalRoot}sources/defpackage/ajh.java`, 'utf8');
const va7 = fs.readFileSync(`${originalRoot}sources/defpackage/va7.java`, 'utf8');
const wa7 = fs.readFileSync(`${originalRoot}sources/defpackage/wa7.java`, 'utf8');
const ksh = fs.readFileSync(`${originalRoot}sources/defpackage/ksh.java`, 'utf8');
const uw2 = fs.readFileSync(`${originalRoot}sources/defpackage/uw2.java`, 'utf8');
const avc = fs.readFileSync(`${originalRoot}sources/defpackage/avc.java`, 'utf8');
const rcDefaults = fs.readFileSync(
  `${originalRoot}resources/res/xml/core_remoteconfig__remote_config_defaults.xml`, 'utf8');
const stringsXml = fs.readFileSync(`${originalRoot}resources/res/values/strings.xml`, 'utf8');

const libraryPage = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8');
const groupSel = fs.readFileSync(
  'note/src/main/ets/core/model/OriginalGroupSelection.ets', 'utf8');
const snapGuides = fs.readFileSync(
  'note/src/main/ets/core/model/OriginalSnapGuides.ets', 'utf8');
const adr0655 = fs.readFileSync(
  'docs/migration/adr/ADR-0655-original-library-home-failclosed.md', 'utf8');
const adr0691 = fs.readFileSync(
  'docs/migration/adr/ADR-0691-original-library-home-flag-correction.md', 'utf8');
const evidence = fs.readFileSync(
  'docs/migration/evidence/original-library-home-flag-correction-jadx-2026-09-25.md', 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 旗标定义链 ---
check(/new ac4\("LIBRARY_HOME", 47, zb4Var, tsb\.c/.test(ac4),
  'ac4.F0 = LIBRARY_HOME(47) PRODUCTION 级 + tsb.c 键');
check(tsb.includes('extends lrb') && tsb.includes('"androidLibraryHome"'),
  'tsb.c = lrb("androidLibraryHome")');
const rcBlock = (key) => {
  const m = rcDefaults.match(new RegExp(`${key}[^]*?<value>(\\w+)`, 'm'));
  return m ? m[1] : null;
};
check(rcBlock('androidLibraryHome') === 'true',
  'androidLibraryHome 打包默认 true —— 原版默认显示 Home');

// --- 消费方锚点 ---
check(ajh.includes('lc4.a(ac4.F0)'), 'ajh:335 门控 Home 导航项插入');
check(va7.includes('lc4.a(ac4.F0)') && wa7.includes('lc4.a(ac4.F0)'),
  'va7/wa7 门控 Home 图标');
check(stringsXml.includes('feature_library__home'), 'strings 含 home 分区标签');
check(ksh.includes('home_record_lecture') || ksh.includes('home_take_notes') ||
  ksh.includes('home_recent_notes') || ksh.includes('home_favorite_notes'),
  'ksh Home 组合族存在');

// --- 同扫描的默认-true 消费旗标复核（防同类误判回归） ---
check(uw2.includes('lc4.a(ac4.V)') , 'ENTITY_GROUPS(ac4.V) 有 uw2 消费方');
check(avc.includes('lc4.a(ac4.Y)'), 'SHAPE_EDIT_SNAPPING(ac4.Y) 有 avc 消费方');
check(rcBlock('androidEntityGroups') === 'true' &&
  rcBlock('androidShapeEditSnapping') === 'true',
  '两键默认 true —— 已移植对齐而非死旗标');
check(groupSel.length > 0 && snapGuides.length > 0,
  'Harmony 组选择/吸附导引已移植');

// --- Harmony 现状与更正登记 ---
// Phase 746 演进：Home 分区已移植（ADR-0694）——Learn 子区
// 仍以资源缺席方式 fail-closed（页面注释提及不计为资源键）。
check(libraryPage.includes('LibrarySection.HOME'),
  'Harmony Home 分区已移植（Phase 746，旗标默认开→已实现）');
check(adr0655.includes('ADR-0691'), 'ADR-0655 已加更正指引');
check(adr0691.includes('androidLibraryHome') && adr0691.includes('延迟移植缺口'),
  'ADR-0691 登记默认开启 + 延迟移植缺口');
check(adr0691.includes('home_study_up_next') && adr0691.includes('ADR-0652'),
  'ADR-0691 注明 study_up_next 仍属 Learn fail-closed');
check(evidence.includes('androidLibraryHome') && evidence.includes('ajh'),
  '证据文档含求值链与消费方');
check(evidence.includes('ENTITY_GROUPS') && evidence.includes('SHAPE_EDIT_SNAPPING'),
  '证据文档含扫描分类（非死旗标更正）');

console.log(`D02_ORIGINAL_LIBRARY_HOME_FLAG_CORRECTION_REPLAY_OK TOTAL=${n} FAILED=0`);
