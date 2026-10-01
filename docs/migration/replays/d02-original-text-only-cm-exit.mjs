// Phase 1400 — text-only OpenedContentManager 退出腿。
// 原版证据（decompiled_1.4.2）：
//   q4i.java   — 退出原因枚举含 OpenedContentManager("Opened Content
//                Manager")：打开内容管理器是 text-only 的自动退出原因之一
//                （JADX 把发射点还原为 fake field，枚举成员本身即契约证据）。
//   c5i.b      — 统一出口；Harmony 端等价物为 textOnlyExitSignal →
//                exitTextOnly('PageAction') → setTextOnly(false,reason)
//                （持久化 + "Showing the full note" toast + 横幅收尾）。
// Phase 1395 把该腿登记为"无对应路径"；Harmony 现有 PageOverviewPanel/
// showPageOverview——本 Phase 在 onTogglePagesPanel 打开腿（false→true）
// 且 textOnlyActive 时补发退出信号。InsertedSticky（无贴纸功能）/
// LegacyDaemon（daemon 内部）维持无对应路径。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const page = readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8');
const canvas = readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// onTogglePagesPanel 是唯一打开入口（page 中唯二赋值为 1794 toggle + 关闭位）。
const toggleIdx = page.indexOf('onTogglePagesPanel: () => {');
check(toggleIdx > 0, 'onTogglePagesPanel exists');
const block = page.slice(toggleIdx, toggleIdx + 900);
check(/photoImportLeaseActive \|\| this\.pageOperationBusy \|\|\s*this\.historyPending/.test(block),
  'lease/busy/history 门禁先行（与兄弟入口一致）');
check(block.includes('OpenedContentManager'), '原版 q4i.OpenedContentManager 注释');
check(/!this\.showPageOverview && this\.textOnlyActive[\s\S]{0,80}?textOnlyExitSignal\+\+/.test(block),
  '打开腿 + textOnlyActive → 退出信号');
check(/textOnlyExitSignal\+\+[\s\S]{0,80}?this\.showPageOverview = !this\.showPageOverview/.test(block),
  '退出信号不拦截面板打开（原版行为：退出 + 打开都发生）');
check(!/showPageOverview && this\.textOnlyActive[\s\S]{0,80}?textOnlyExitSignal\+\+/.test(block.split('if (!this.showPageOverview').pop() ?? ''),
  '关闭腿（true→false）不发信号');

// 信号出口完整性：textOnlyExitSignal → 统一出口 → 持久化 + toast。
check(/@Prop @Watch\('onTextOnlyExitSignalChange'\) textOnlyExitSignal/.test(canvas),
  'canvas exit-signal prop');
check(/onTextOnlyExitSignalChange[\s\S]{0,150}?exitTextOnly\('PageAction'\)/.test(canvas),
  'signal → exitTextOnly(PageAction)');
check(/private setTextOnly\(on: boolean, exitReason[\s\S]{0,2500}?persistIsTextOnly\(on\)/.test(canvas),
  'exit persists is_text_only=false');
check(/exitReason !== null && exitReason !== 'ManualExit'[\s\S]{0,150}?text_only_auto_exit/.test(canvas),
  '非手动退出 → "Showing the full note" toast');

console.log(`d02-original-text-only-cm-exit OK — ${n} checks`);
