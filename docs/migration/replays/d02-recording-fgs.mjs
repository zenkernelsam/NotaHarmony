// Phase 834 — RecordingForegroundService 代码语义
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources';
const svc = readFileSync(join(S, 'com/gingerlabs/notability/feature/note/toolbox/audio/record/RecordingForegroundService.java'), 'utf8');
const harm = readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/core/adaptation/OriginalRecordingSourceBackend.ets', 'utf8');

const results = [];
const ck = (n, ok) => results.push([n, ok]);

// 启动合约
ck('process_token 校验', svc.includes('"process_token"'));
ck('stale start 守卫日志', svc.includes('stale start'));
ck('startForeground id=2001', svc.includes('startForeground(2001'));
ck('START_NOT_STICKY 返回(return 2)', /onStartCommand[\s\S]{0,1400}return 2/.test(svc));
ck('会话计数 zt5 状态机', svc.includes('zt5') && svc.includes('AtomicReference'));
ck('WakeLock 限时获取 wg4.g', svc.includes('.acquire(wg4.g('));
ck('ServiceStartNotAllowed 降级', svc.includes('ServiceStartNotAllowedException'));

// 通知
ck('channel notability_recording LOW(2)', svc.includes('new NotificationChannel("notability_recording"') && /notability_recording"[\s\S]{0,200},\s*2\)\)/.test(svc));
ck('app_mark icon + 常驻 flag', svc.includes('ui_designsystem__app_mark') && svc.includes('flags |= 2'));
ck('通知 title 字符串', svc.includes('recording_notification_title'));

// 生命周期
ck('onBind null', /onBind\(Intent[\s\S]{0,80}return null/.test(svc));
ck('onDestroy wakelock 释放', /onDestroy[\s\S]{0,200}isHeld\(\)[\s\S]{0,80}release\(\)/.test(svc));

// Harmony
ck('Harmony AUDIO_RECORDING 连续任务', harm.includes('BackgroundMode.AUDIO_RECORDING'));
ck('Harmony wantAgent START_ABILITY', harm.includes('OperationType.START_ABILITY'));
ck('Harmony stopBackgroundRunning', harm.includes('stopBackgroundRunning'));

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
