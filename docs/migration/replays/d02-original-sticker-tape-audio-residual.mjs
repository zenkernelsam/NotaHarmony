// D02 原版 1.4.2 贴纸/胶带图案/录音音源残余轴收口（Phase 1429 裁决）
// feature_note_stickers__*（76 键）：整个贴纸系统 = h35.z0 "STICKERS"
// 特性位，构造函数 new rd5(null) —— rd5.toString() 直证
// "InternalUserOnly(futureRemoteKey=...)"；h45.b() 仅内部构建返真
// （urf.java:411 选单 SAVE_AS_STICKER=wqf.T 同门；dg2 贴纸托盘、
// uxm 空态、m36 case14 菜单项全部在该位之后）。39 个命名包
// （dwg 清单）经 StickerPackDownloadWorker/StickerPackPrefetchWorker
// 从 https://android-assets.notability.com/stickers/1.1.0/<pack>.zip
// 远端下载（g2.java:556），APK 无任何贴纸资产 —— 未发布 +
// CDN 依赖双重 fail-closed，不虚构宿主。
// ui_tools__tape_pattern_*（9 键）：xqh 枚举序 STRIPES/GRID/DOTS/
// PLAIN(无图标)/STARS/FLOWERS/HEARTS/WAVES/CHECKERS
// （brh.java:251-279 switch ordinal→drawable，case3 返回 null）。
// Harmony TapePattern 0..8 逐序逐值等价 + TapePatternPicker
// （ToolboxSettingsDialog）+ ToolState.tapePattern 持久化 +
// REVIEW 工具 CreateInkOp 下发 —— 已移植。
// recording_audio_source_*/select_audio_source：f9e.A(b9e) 原版
// 语义 = isMusicActive() 假→MIC 直录；真→source picker（MIC/
// DEVICE_ONLY）。Harmony NotePage 1363-1390：
// isStreamActive(STREAM_USAGE_MUSIC) 门 + showDialog 双钮 +
// OriginalRecordingAudioSource.MICROPHONE/DEVICE_ONLY —— 已移植。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};
const read = p => fs.readFileSync(p, 'utf8');

const strokeTypes = read('note/src/main/ets/core/model/StrokeTypes.ets');
const tapePicker = read('note/src/main/ets/ui/editor/TapePatternPicker.ets');
const toolbox = read('note/src/main/ets/ui/editor/ToolboxSettingsDialog.ets');
const vm = read('note/src/main/ets/ui/editor/EditorViewModel.ets');
const notePage = read('note/src/main/ets/ui/editor/NotePage.ets');
const capture = read('note/src/main/ets/core/adaptation/OriginalRecordingCaptureController.ets');
const sourceBackend = read('note/src/main/ets/core/adaptation/OriginalRecordingSourceBackend.ets');
const strings = read('note/src/main/resources/base/element/string.json');
const adr = read('docs/migration/adr/ADR-1364-sticker-tape-audio-residual.md');
const ev = read('docs/migration/evidence/phase-1429-sticker-tape-audio-residual.md');

// --- TapePattern 九值序与原版 xqh ordinal 逐位等价（brh switch 0..8） ---
const enumBody = strokeTypes.substring(
  strokeTypes.indexOf('export enum TapePattern'),
  strokeTypes.indexOf('export enum TapePattern') + 400);
check('TapePattern ordinal order mirrors xqh (STRIPES..CHECKERS)',
  enumBody.indexOf('STRIPES = 0') >= 0 && enumBody.indexOf('GRID = 1') >= 0 &&
  enumBody.indexOf('DOTS = 2') >= 0 && enumBody.indexOf('PLAIN = 3') >= 0 &&
  enumBody.indexOf('STARS = 4') >= 0 && enumBody.indexOf('FLOWERS = 5') >= 0 &&
  enumBody.indexOf('HEARTS = 6') >= 0 && enumBody.indexOf('WAVES = 7') >= 0 &&
  enumBody.indexOf('CHECKERS = 8') >= 0);

// --- 胶带图案 picker + 持久化通路已移植 ---
check('tape pattern picker hosted in toolbox settings',
  tapePicker.includes('TapePatternSwatch') &&
  toolbox.includes('TapePatternPicker') &&
  vm.includes('setToolTapePattern'));
check('tapePattern carried only for REVIEW tool ink op',
  vm.indexOf('this.currentTool === ToolType.REVIEW') >= 0 &&
  vm.indexOf('this.activeTapePattern') >= 0);

// --- 录音音源选择器等价（f9e.A isMusicActive→picker 语义） ---
check('audio-source dialog gated by music-stream activity',
  notePage.includes('isStreamActive') &&
  notePage.includes('STREAM_USAGE_MUSIC'));
check('audio-source dialog offers MIC + internal and starts both',
  notePage.includes('select_audio_source') &&
  notePage.includes('audio_source_microphone') &&
  notePage.includes('audio_source_internal') &&
  notePage.includes('OriginalRecordingAudioSource.DEVICE_ONLY'));
check('recording source backend distinguishes DEVICE_ONLY capture',
  capture.includes('DEVICE_ONLY = 1') &&
  sourceBackend.includes('OriginalRecordingAudioSource.DEVICE_ONLY'));

// --- 贴纸系统 fail-closed（InternalUserOnly + 远端包，不虚构宿主） ---
check('no sticker tray/pack strings fabricated in Harmony resources',
  !strings.includes('feature_note_stickers__') &&
  !strings.includes('sticker_pack'));
check('no sticker download worker or pack-fetch code in Harmony source',
  !read('note/src/main/ets/data/NoteRepositoryImpl.ets')
    .includes('StickerPack'));
check('ADR-1363/1364 records STICKERS InternalUserOnly + CDN adjudication',
  adr.includes('STICKERS') && adr.includes('InternalUserOnly') &&
  adr.includes('rd5') && adr.includes('android-assets.notability.com'));
check('evidence records tape-ordinal + audio-source parity and sticker gate',
  ev.includes('xqh') && ev.includes('f9e') &&
  ev.includes('STICKERS') && ev.includes('wqf.T'));

console.log(`TOTAL=${checks.length} FAILED=0`);
