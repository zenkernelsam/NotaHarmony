// D02 原版 ON_BACKGROUND 冲刷对等（Phase 1432）
// 原版证据：MainActivity.onPause 仅注销加速度传感器、onDestroy 仅做
// Play 评审（nu6/mqg）+ S Pen quick-tools 清理 —— 无显式落盘。f80
// 生命周期监听实现仅 mua（OTel 派发闸门）+ y10（ANR 看门狗 1s 调度
// b20），均为遥测。原版笔记状态经 zhi.emit→tee.a0 按变更写穿透库，
// 文本编辑态本身即文档模型字段 —— 后台/进程回收不丢稿。
// Harmony 差异：editingDraftText/标题草稿是进程内缓冲，
// LatestWriteQueue 挂起写亦然；onBackground 原为 stub —— 系统回收
// 后台进程即丢稿。补齐：EditorLifecycleFlush 登记 + onBackground
// 尽力冲刷 = performLeaveEditor 前半（无导航/不停录音 —— 原版
// RecordingForegroundService 前台服务使录音后台续录）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};
const read = p => fs.readFileSync(p, 'utf8');

const registry = read('note/src/main/ets/data/EditorLifecycleFlush.ets');
const ability = read('note/src/main/ets/noteability/NoteAbility.ets');
const page = read('note/src/main/ets/ui/editor/NotePage.ets');
const adr = read('docs/migration/adr/ADR-1367-background-flush-parity.md');
const ev = read('docs/migration/evidence/phase-1432-background-flush.md');

// --- 登记模块 ---
check('registry exposes register/unregister/flush API',
  registry.includes('export function registerBackgroundFlush') &&
  registry.includes('export function unregisterBackgroundFlush') &&
  registry.includes('export function flushEditorsForBackground'));
check('registry callbacks fire-and-forget with error swallow',
  /callback\(\)\.catch/.test(registry));
check('registry comment cites original write-through evidence',
  registry.includes('zhi') && registry.includes('tee.a0'));

// --- Ability 接线 ---
check('NoteAbility imports flushEditorsForBackground',
  ability.includes("import { flushEditorsForBackground } from '../data/EditorLifecycleFlush'"));
check('onBackground triggers registered flush',
  /onBackground\(\): void \{[\s\S]*?flushEditorsForBackground\(\)/.test(ability));

// --- NotePage 注册/注销 ---
check('aboutToAppear registers background flush',
  /aboutToAppear\(\): void \{\s*this\.backgroundFlushToken = registerBackgroundFlush/.test(page));
check('aboutToDisappear unregisters before teardown',
  /aboutToDisappear\(\): void \{\s*this\.editorDisposed = true;\s*if \(this\.backgroundFlushToken >= 0\)/.test(page));

// --- 冲刷体语义（= performLeaveEditor 前半，无导航/录音停） ---
const flushBody = page.match(
  /private async flushPendingEditsForBackground\(\): Promise<void> \{([\s\S]*?)\n  \}/);
check('flushPendingEditsForBackground exists', flushBody !== null);
const body = flushBody[1];
check('background flush commits pending title edit',
  body.includes('this.editingTitle') && body.includes('this.saveTitle()') &&
  body.includes('this.titleSaveQueue'));
check('background flush flushes page queue via historyBridge (commits text draft)',
  body.includes('this.historyBridge.flushCurrentPage()'));
check('background flush flushes tool state + recording deletes',
  body.includes('this.viewModel.flushToolState()') &&
  body.includes('this.recordingDeleteController.flush()'));
check('background flush skips during leases and in-flight leave',
  body.includes('this.editorLeavePromise !== null') &&
  body.includes('this.photoImportLeaseActive') && body.includes('this.pageStructureLeaseActive'));
check('background flush does NOT navigate back or stop recording (original foreground-service parity)',
  !body.includes('router.back()') && !body.includes('finishRecordingSession') &&
  !body.includes('recordingController.release'));

// --- 文档 ---
check('ADR-1367 records original evidence (onPause sensor / f80 telemetry / zhi emit)',
  adr.includes('onPause') && adr.includes('mua') && adr.includes('y10') && adr.includes('zhi'));
check('ADR-1367 records fail-closed exclusions (recording continues in background)',
  adr.includes('RecordingForegroundService'));
check('evidence doc records the draft-loss gap and the fix',
  ev.includes('editingDraftText') && ev.includes('onBackground'));

console.log(`TOTAL=${checks.length} FAILED=0`);
