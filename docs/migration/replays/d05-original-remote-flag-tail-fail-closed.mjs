// D05 原版 ac4 远程旗标尾项 fail-closed 总登记 — Phase 710
// （ADR-0658）。对尾项旗标的消费方逐一 pin 原版证据，并验证
// Harmony 呈现旗标关闭态（可选行/项不出现）或已由实现覆盖。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');
const JADX = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const ac4 = read(`${JADX}/sources/defpackage/ac4.java`);
const read$ = (f) => read(`${JADX}/sources/defpackage/${f}.java`);

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- A 类：可选行/项（旗标关闭=不出现）---
check(ac4.includes('"NOTE_TOOLBOX_SECONDARY_TOOLS", 22') &&
  read$('ch2').includes('lc4.a(ac4.h0)') &&
  read$('ys2').includes('lc4.a(ac4.h0)'),
  'h0 SECONDARY_TOOLS → ch2/ys2 二级工具条');
check(ac4.includes('"SETTINGS_NAV_PAGES", 59') &&
  read$('s3d').includes('lc4.a(ac4.Q0)') &&
  read$('s3d').includes('connected_services'),
  'Q0 NAV_PAGES → s3d 新导航结构');
check(read$('s3d').includes('lc4.a(ac4.n0)'),
  'n0 MANAGE_SUBSCRIPTION → s3d 行过滤');
check(/ac4\.S0/.test(read$('od')) &&
  /ac4\.J0/.test(read$('od')) &&
  /ac4\.P\b/.test(read$('od')),
  'S0/J0 → od ⋮ 菜单设置链接');
check(/ac4\.P0/.test(read$('ks')) &&
  /ac4\.r0/.test(read$('ks')),
  'P0/r0 → ks 手写绘图/识别开关行');
check(read$('q0').includes('lc4.a(ac4.R0)') &&
  read$('q0').includes('lc4.a(ac4.U0)') &&
  read$('q0').includes('lc4.a(ac4.N0)'),
  'R0/U0/N0 → q0 设置可选行');
check(read$('x22').includes('lc4.a(ac4.T0)'), 'T0 PRO_INFO → x22 行');
check(read$('fdi').includes('lc4.a(ac4.V0)'),
  'V0 SECTION_PICKER → fdi 标签页变体');
check(read$('cd').includes('lc4.a(ac4.K0)') &&
  read$('cd').includes('feature_library__templates'),
  'K0 → cd 库新建菜单 Templates 项');
check(read$('n9j').includes('lc4.a(ac4.w0)') &&
  read$('n9j').includes('content_manager_create_template'),
  'w0 → n9j 内容管理器 Create template');
check(read$('d5j').includes('lc4.a(ac4.q0)') &&
  read$('d5j').includes('copy_note_id'),
  'q0 → d5j Copy note ID 项');
check(read$('x90').includes('lc4.a(ac4.s0)'), 's0 → x90 调试菜单');

// --- B 类：订阅/后端/私有 API ---
check(read$('en9').includes('lc4.a(ac4.l0)'),
  'l0 NOTE_LIMIT → en9 免费层上限');
check(read$('gti').includes('lc4.a(ac4.m0)') &&
  read$('gti').includes('KeyguardManager'),
  'm0 UNLOCKED → gti KeyguardManager（Android-only）');
check(read$('rt8').includes('lc4.a(ac4.j0)'),
  'j0 SIX_MONTHS → rt8 订阅时长引导');
check(read$('m60').includes('lc4.a(ac4.H0)'),
  'H0 ROOM_SEARCH → m60 DI 引擎选型');
check(read$('tt8').includes('lc4.a(ac4.o0)'),
  'o0 PAYWALL_PROMO → tt8 付费墙推广');
check(read$('kr8').includes('lc4.a(ac4.X)') &&
  read$('rs3').includes('lc4.a(ac4.X)'),
  'X COLLAB_RTL → kr8/rs3 协作 CRDT RTL');

// --- C 类：死旗标（无消费方）---
import { readdirSync } from 'node:fs';
const defs = readdirSync(`${JADX}/sources/defpackage`)
  .filter((f) => f.endsWith('.java') && f !== 'ac4.java')
  .map((f) => read(`${JADX}/sources/defpackage/${f}`));
for (const [field, name] of [['g0', 'HANDWRITING_TO_TEXT'],
  ['G0', 'SINGULAR_ATTRIBUTION'], ['U\\b', 'DESELECT_MODE'],
  ['v0', 'LIVE_TRANSCRIPTION']]) {
  const re = new RegExp(`ac4\\.${field}`);
  check(!defs.some((s) => re.test(s)), `${name} 1.0.3 内无消费方`);
}

// --- Harmony 侧：旗标关闭态 / 已实现开态 ---
const settings = read('note/src/main/ets/ui/settings/SettingsPage.ets');
check(!/newsletter|diagnostic|pro_info|manage_subscription|connected_services/i
  .test(settings), 'Harmony 设置无旗标门控行');
check(settings.includes('note_view_night_mode'),
  'Harmony 已实现 note_view_night_mode（N0 开态语义）');
const toolbar = read('note/src/main/ets/ui/editor/EditorToolbar.ets');
check(/style_dash|BrushStyle\.DASH/.test(toolbar),
  'Harmony 已实现 stroke-style（W 开态语义）');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
check(/selectionGroups|selectedGroupIds/.test(canvas),
  'Harmony 已实现实体组选择（V 开态语义）');

// --- ADR/证据 ---
check(read('docs/migration/adr/ADR-0658-original-remote-flag-tail-failclosed.md')
  .includes('NOTE_LIMIT'), 'ADR-0658 登记尾项旗标');
check(read('docs/migration/evidence/original-remote-flag-tail-jadx-2026-09-25.md')
  .includes('KeyguardManager'), '证据文档记录私有 API 依赖');

console.log(`D05_ORIGINAL_REMOTE_FLAG_TAIL_FAIL_CLOSED_OK TOTAL=${total} FAILED=0`);
