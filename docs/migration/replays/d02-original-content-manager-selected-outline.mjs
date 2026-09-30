// Phase 1396 — content_manager 面板开合 outline 切换（ADR-1306 遗留接线）。
// 原版证据（decompiled_1.4.2）：
//   fp0.java 注册 p2c RichIcon = ui_designsystem__content_manager，
//   携带 fill + overlay + outline_default/outline_selected 双轮廓——
//   页面管理器面板开合时切换轮廓（gs8 case2 顶栏首项开关）。
// Harmony 行为（本 Phase）：
//   - TOOL_GLYPHS 已有 content_manager_selected 提取（Phase 1370），
//     本 Phase 把 showPageOverview 经 @Prop 透传进 EditorToolbar；
//   - 面板开 → 'content_manager_selected'、关 → 'content_manager'；
//   - bindSheet(showPageOverview) 双向同步——滑走关闭同样回落默认轮廓。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const TOOLBAR = 'note/src/main/ets/ui/editor/EditorToolbar.ets';
const PAGE = 'note/src/main/ets/ui/editor/NotePage.ets';
const GLYPHS = 'note/src/main/ets/ui/components/ToolGlyphs.ets';

const toolbar = readFileSync(TOOLBAR, 'utf8');
const page = readFileSync(PAGE, 'utf8');
const glyphs = readFileSync(GLYPHS, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// === 1. 双轮廓字形已提取（Phase 1370 既有数据）===
check(/'content_manager':\s*\{/.test(glyphs), 'content_manager glyph present');
check(/'content_manager_selected':\s*\{/.test(glyphs),
  'content_manager_selected glyph present');
const defMatch = glyphs.match(/'content_manager':\s*\{[^}]*o:\s*`([^`]+)`/);
const selMatch = glyphs.match(/'content_manager_selected':\s*\{[^}]*o:\s*`([^`]+)`/);
check(defMatch !== null && selMatch !== null &&
  defMatch[1] !== selMatch[1],
  'default vs selected outlines differ (fp0 双轮廓语义)');

// === 2. 状态透传 ===
check(/@Prop pagesPanelOpen: boolean = false/.test(toolbar),
  'EditorToolbar takes pagesPanelOpen prop');
check(/pagesPanelOpen: this\.showPageOverview/.test(page),
  'NotePage passes showPageOverview');
check(/@State showPageOverview: boolean = false/.test(page),
  'showPageOverview is NotePage state');
check(/\.bindSheet\(this\.showPageOverview/.test(page),
  'bindSheet two-way sync (滑走关闭回落默认轮廓)');

// === 3. 按钮轮廓切换 ===
check(/glyph: this\.pagesPanelOpen \? 'content_manager_selected' : 'content_manager'/.test(toolbar),
  'glyph switches on panel state');
check(/onTogglePagesPanel/.test(toolbar), 'toggle callback unchanged');
check(/cd_pages_panel_toggle/.test(toolbar), 'a11y label unchanged');
check(/this\.showPageOverview = !this\.showPageOverview/.test(page),
  'toggle flips showPageOverview');
check(/this\.showPageOverview = false/.test(page),
  'explicit close path resets state');

console.log(`d02-original-content-manager-selected-outline OK — ${n} checks`);
