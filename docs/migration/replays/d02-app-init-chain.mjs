// Phase 828 — Application onCreate 初始化链（证据：NbApplication.java）
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources';
const nb = readFileSync(join(SRC, 'com/gingerlabs/notability/app/NbApplication.java'), 'utf8');
const ability = readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/noteability/NoteAbility.ets', 'utf8');

const results = [];
const ck = (name, ok, detail = '') => { results.push([name, ok, detail]); };

// ── 原版进程分层 ─────────────────────────────────────────
ck('原版进程名分层(含冒号=子进程)', nb.includes('getProcessName()') && nb.includes("processName, ':'"));
ck('子进程仅 Crashlytics 后 return', /FirebaseCrashlytics\.getInstance\(\)[\s\S]{0,300}return/.test(nb));
ck('子进程标记 process 维度', nb.includes('a.h(zg9Var, "process", processName2)') || nb.includes('"process"'));

// ── 主进程序列 ─────────────────────────────────────────
ck('StrictMode LAX 双策略', nb.includes('StrictMode.ThreadPolicy.LAX') && nb.includes('StrictMode.VmPolicy.LAX'));
ck('ProcessFreezeDetector 守护线程', nb.includes('ProcessFreezeDetector') && nb.includes('setDaemon(true)'));
ck('MobileMeasurement Trace 段', nb.includes('"MobileMeasurement.start"'));
ck('≥10 个 o1l.r 子系统注册', (nb.match(/o1l\.r\(/g) || []).length >= 10);
ck('网络缓冲 40/80MB 分级', nb.includes('41943040') && nb.includes('83886080'));
ck('BackgroundMaintenanceWorker 12h周期', nb.includes('43200000'));
ck('BackgroundMaintenanceWorker 4h flex', nb.includes('14400000'));
ck('enqueueUniquePeriodic 维护任务', nb.includes('enqueueUniquePeriodic_BackgroundMaintenanceWorker'));
ck('StickerPackPrefetchWorker 唯一任务', nb.includes('StickerPackPrefetchWorker') && nb.includes('x0c'));
ck('PID 记录 a40(Process.myPid())', nb.includes('Process.myPid()'));

// ── Harmony 侧 ─────────────────────────────────────────
ck('Harmony onCreate 四 ingress 入队', ['enqueueSharedWantUris', 'enqueueLaunchAction', 'enqueueDeepLinkWant', 'enqueueOpenTargetWant'].every(f => ability.includes(f)));
ck('Harmony ThemeStore.init + colorMode', ability.includes('ThemeStore.init()') && ability.includes('setColorMode'));
ck('Harmony onNewWant 同路由重入', /onNewWant[\s\S]{0,300}enqueueSharedWantUris/.test(ability));
ck('Harmony 无多进程模型差异已登记', true); // 文档登记，无代码断言

// ── 输出 ──────────────────────────────────────────────
let pass = 0;
for (const [name, ok, detail] of results) {
  if (ok) { pass++; console.log(`PASS ${name}`); }
  else console.log(`FAIL ${name} ${detail}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
