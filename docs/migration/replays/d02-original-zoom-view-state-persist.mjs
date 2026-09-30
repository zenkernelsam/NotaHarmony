// Phase 1394 — 放大窗 sourceRect/shown 持久化 + 冷启动恢复。
// 原版证据（decompiled_1.4.2）：
//   wmb.java:75/102 — UPDATE NoteStateEntity SET zoomViewShown / zoomViewSourceRect
//                     WHERE id=?（ymb 专属列写，不动 zoom/scroll）。
//   ws3.java:295    — SELECT zoomViewShown WHERE id=?（按笔记恢复读）。
//   ten.java:103/118 — sbe 序列化 "l,t,r,b" 逗号串；y() 解析失败回落 sbe.e。
//   kck.java / rck.java:19 — ZoomViewState(isShown,dockEdge,sourceRectDocPx,…)，
//                     初值 isShown=false/空矩形；kck.a mask62 隐窗时保留 sourceRect。
//   kdk.java:46-54  — A() 隐窗仅清 isShown（mask 62）→ 会话内重开保持原位。
// Harmony 行为（本 Phase）：
//   - getViewState 载入 zoomViewSourceRect/zoomViewShown 作恢复种子；
//   - initZoomSourceRect 优先恢复持久化位置，无值才回落末笔锚定；
//   - 窗口拖动/步进/自动前进/回位/卸载落点均持久化 "l,t,r,b"；
//   - 面板挂载写 shown=true；卸载按当时工具是否仍 ZOOM 写回
//     （整页导航离开保持 true → 重开笔记自动恢复放大窗 = selectTool(ZOOM)）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const REPO = 'note/src/main/ets/data/NoteRepositoryImpl.ets';
const IFACE = 'note/src/main/ets/data/RepositoryInterfaces.ets';
const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';

const repo = readFileSync(REPO, 'utf8');
const iface = readFileSync(IFACE, 'utf8');
const canvas = readFileSync(CANVAS, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// === 1. 仓储专属写路径（wmb/ymb 等价 partial update）===
check(/async saveZoomViewSourceRect\(noteId: string, rect: string \| null\)/.test(repo),
  'saveZoomViewSourceRect signature');
check(/async saveZoomViewShown\(noteId: string, shown: boolean\)/.test(repo),
  'saveZoomViewShown signature');
check(/base\.zoomViewSourceRect = rect/.test(repo) &&
  /base\.zoomViewShown = shown/.test(repo),
  'writers mutate preserved field then saveViewState (无丢列)');
check(/saveZoomViewSourceRect\(noteId: string, rect: string \| null\)/.test(iface) &&
  /saveZoomViewShown\(noteId: string, shown: boolean\)/.test(iface),
  'interface exposes both writers');

// === 2. 载入恢复种子 ===
check(/restoredZoomSourceRect = this\.parseZoomSourceRect/.test(canvas),
  'load seeds restoredZoomSourceRect from zoomViewSourceRect');
check(/persistedZoomViewShown = state\?\.zoomViewShown/.test(canvas),
  'load seeds persistedZoomViewShown');

// === 3. ten.y 解析：四元逗号串 + 合法矩形校验 ===
check(/rect\.split\(','\)/.test(canvas), 'parse splits on comma');
check(/parts\.length !== 4/.test(canvas), 'parse requires 4 fields');
check(/r <= l \|\| b <= t/.test(canvas), 'parse rejects degenerate rect');

// === 4. initZoomSourceRect 优先恢复持久化位 ===
check(/if \(this\.restoredZoomSourceRect !== null\) \{[\s\S]{0,200}?clampZoomSource\(/.test(canvas),
  'initZoomSourceRect restores persisted position before anchors');

// === 5. 落点持久化覆盖全部 sourceRect 变更 ===
check(/endZoomWindowDrag\(\): void \{[\s\S]{0,400}?persistZoomViewSourceRect\(\)/.test(canvas),
  'window drag settle persists sourceRect');
check(/zoomStepBack\(\): void \{[\s\S]{0,300}?persistZoomViewSourceRect\(\)/.test(canvas),
  'zoomStepBack persists sourceRect');
check(/zoomStepForward\(\): void \{[\s\S]{0,300}?persistZoomViewSourceRect\(\)/.test(canvas),
  'zoomStepForward persists sourceRect');
check(/zoomAutoAdvance[\s\S]{0,700}?persistZoomViewSourceRect\(\)/.test(canvas),
  'zoomAutoAdvance persists sourceRect after advance');
check(/zoomReturnToInk\(\): void \{[\s\S]{0,900}?persistZoomViewSourceRect\(\)/.test(canvas),
  'zoomReturnToInk persists sourceRect');
check(/`\$\{l\},\$\{t\},\$\{l \+ rectW\},\$\{t \+ rectH\}`/.test(canvas),
  'serializes "l,t,r,b" (ten.r format)');
check(/restoredZoomSourceRect = \{ x: l, y: t \}/.test(canvas),
  'persist mirrors in-session rect (kck 会话内保留语义)');

// === 6. zoomViewShown 写回 + 冷启动恢复 ===
check(/\.onAppear\([\s\S]{0,200}?persistZoomViewShown\(true\)/.test(canvas),
  'panel mount persists zoomViewShown=true');
check(/persistZoomViewShown\(this\.viewModel\.currentTool === ToolType\.ZOOM\)/.test(canvas),
  'panel unmount persists shown = still-ZOOM (导航离开保持 true)');
check(/persistedZoomViewShown === true[\s\S]{0,150}?selectTool\(ToolType\.ZOOM\)/.test(canvas),
  'cold-open with shown=true re-activates ZOOM (原版 isShown 恢复)');

console.log(`d02-original-zoom-view-state-persist OK — ${n} checks`);
