// Phase 729 — manifest 组件审计 + 录音后台续录长时任务
// 证据：RecordingForegroundService startForeground+WakeLock(24h) →
//   AUDIO_RECORDING 长时任务；AudioCaptureService → InternalAudioBackend。
import fs from 'node:fs';
import path from 'node:path';

const REPO = path.resolve(process.cwd());
const R = (p) => path.join(REPO, p);
const read = (p) => fs.readFileSync(R(p), 'utf8');

let total = 0, failed = 0;
const check = (name, cond) => {
  total++;
  if (!cond) { failed++; console.log(`  FAIL ${name}`); }
};

// === 长时任务实现 ===
const src = read('note/src/main/ets/core/adaptation/OriginalRecordingSourceBackend.ets');
check('导入 backgroundTaskManager', /@kit\.BackgroundTasksKit/.test(src));
check('导入 wantAgent', /wantAgent/.test(src));
check('AUDIO_RECORDING 长时任务',
  /BackgroundMode\.AUDIO_RECORDING/.test(src));
check('startBackgroundRunning 调用', /startBackgroundRunning\(/.test(src));
check('stopBackgroundRunning 调用', /stopBackgroundRunning\(/.test(src));
check('start 成功后开任务（beginContinuousTask）',
  /await selected\.start\(\)[\s\S]*?beginContinuousTask/.test(src));
check('stop 的 finally 里收任务', /finally[\s\S]*?endContinuousTask/.test(src));
check('abort 收任务', /abort\(\)[\s\S]*?endContinuousTask/.test(src));
check('任务启动失败不阻断录音', /catch\s*\{[\s\S]*?continuousTaskRunning = false/.test(src));
check('start 失败清空 active（修残留 bug）',
  /catch \(error\)[\s\S]*?this\.active = null/.test(src));
check('wantAgent 回拉 NoteAbility', /abilityName: 'NoteAbility'/.test(src));
check('START_ABILITY operationType', /START_ABILITY/.test(src));

// === 权限声明 ===
const mod = read('note/src/main/module.json5');
check('KEEP_BACKGROUND_RUNNING 权限', /KEEP_BACKGROUND_RUNNING/.test(mod));
check('MICROPHONE 权限仍在', /ohos\.permission\.MICROPHONE/.test(mod));
check('viewData+sendData+sendMultipleData skills',
  /ohos\.want\.action\.viewData/.test(mod) &&
  /ohos\.want\.action\.sendData/.test(mod) &&
  /ohos\.want\.action\.sendMultipleData/.test(mod));
check('file:application/pdf uri', /application\/pdf/.test(mod));
check('notability.com/app/note 深链', /notability\.com/.test(mod));
check('NoteFormAbility 卡片能力', /NoteFormAbility/.test(mod));

// === 构造注入 ===
const page = read('note/src/main/ets/ui/editor/NotePage.ets');
check('SourceBackend 第三参传 context',
  /new OriginalRecordingInternalAudioBackend\(context\.tempDir\), context\)/.test(page));

// === 文档 ===
const adr = read('docs/migration/adr/ADR-0677-original-manifest-components.md');
check('ADR-0677 存在', adr.length > 500);
check('ADR 覆盖 RecordingForegroundService', /RecordingForegroundService/.test(adr));
check('ADR 覆盖 AppUpgradeReceiver=ProfileInstaller', /profileinstaller|AppUpgradeReceiver/.test(adr));
check('ADR 覆盖 FileProvider 边界', /ExportFileProvider|FileProvider/.test(adr));
check('ADR 覆盖 CREATE_NOTE', /CREATE_NOTE/.test(adr));
check('ADR 覆盖 MissingNativeLibraryActivity', /MissingNativeLibraryActivity/.test(adr));
check('ADR 覆盖 sign-in activity 边界', /AppleSignInActivity|MicrosoftSignInActivity/.test(adr));
check('ADR 覆盖 wake lock 等价', /WAKE_LOCK|wake lock|WakeLock/i.test(adr));

const ev = read('docs/migration/evidence/original-manifest-components-jadx-2026-09-25.md');
check('证据文档存在', ev.length > 400);
check('证据覆盖 service 表', /AudioCaptureService/.test(ev));
check('证据覆盖 receiver/provider 表', /WidgetProvider|ExportFileProvider/.test(ev));
check('证据覆盖权限对表', /uses-permission|KEEP_BACKGROUND_RUNNING|USE_BIOMETRIC/.test(ev));

const report = read('docs/migration/reports/phase-729-original-manifest-components.md');
check('中文报告存在', report.length > 500);
check('报告引用原版证据', /RecordingForegroundService|manifest/.test(report));

console.log(`D02_ORIGINAL_MANIFEST_COMPONENTS_REPLAY_OK TOTAL=${total} FAILED=${failed}`);
process.exit(failed === 0 ? 0 : 1);
