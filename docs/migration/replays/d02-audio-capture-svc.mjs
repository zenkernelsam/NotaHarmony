// Phase 835 — AudioCaptureService 代码语义（媒体内录）
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const svc = readFileSync(join('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources',
  'com/gingerlabs/notability/feature/note/toolbox/audio/record/wrapper/audio/AudioCaptureService.java'), 'utf8');

const results = [];
const ck = (n, ok) => results.push([n, ok]);

// FGS + 渠道
ck('FGS id=123', svc.includes('startForeground(123'));
ck('channel AudioCapture channel', svc.includes('"AudioCapture channel"'));
ck('渠道名 Notability Audio Capture Service Channel', svc.includes('Notability Audio Capture Service Channel'));
ck('importance=3(DEFAULT)', /NotificationChannel\([^)]*"AudioCapture channel"[^)]*,\s*3\)/.test(svc));

// action 分发
ck('Start action', svc.includes('"AudioCaptureService:Start"'));
ck('ResultData extra', svc.includes('"AudioCaptureService:Extra:ResultData"'));
ck('getMediaProjection(-1)', svc.includes('getMediaProjection(-1'));
ck('NOT_STICKY 返回', /onStartCommand[\s\S]{0,600}return 2/.test(svc));
ck('FGS 异常双降级', svc.includes('ForegroundServiceStartNotAllowedException') && svc.includes('SecurityException'));

// 音频参数
ck('AudioPlaybackCaptureConfiguration', svc.includes('AudioPlaybackCaptureConfiguration'));
ck('USAGE_MEDIA addMatchingUsage(1)', svc.includes('addMatchingUsage(1)'));
ck('PCM16 encoding=2', svc.includes('setEncoding(2)'));
ck('44100Hz + mono(16)', svc.includes('setSampleRate(44100)') && svc.includes('setChannelMask(16)'));
ck('1024 读缓冲', svc.includes('read(sArr, 0, 1024)'));

// 输出
ck('AudioCaptures/Recording-*.pcm', svc.includes('AudioCaptures') && svc.includes('Recording-') && svc.includes('.pcm'));
ck('日期格式 dd-MM-yyyy-hh-mm-ss', svc.includes('dd-MM-yyyy-hh-mm-ss'));
ck('onBind null', /onBind\(Intent[\s\S]{0,80}return null/.test(svc));

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
