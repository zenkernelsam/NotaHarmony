// D02 原版 1.4.2 Manifest + 残余资源轴收口（Phase 1428 裁决）
// Manifest 一版组件：AudioCaptureService/RecordingForegroundService（录音
// 前台服务 → Harmony backgroundTaskManager 连续任务已移植）、
// ApiGatedFirebaseInitProvider（GMS init）、ExportFileProvider
// （FileProvider 分享 URI → Harmony 系统分享通路）、AppUpgradeReceiver
// （仅写 ART baseline profile，无应用数据工作）、HwrEngineService
// （MyScript iink 绑定服务 → 随 ADR-0645 后端门禁 fail-closed）、
// 5 个 widget provider（ADR-0632/0634-0636/0680）；其余为 Play assetpacks/
// WorkManager/Firebase/MLKit/GMS/Room vendored。
// res/raw：inky_2026_v32.riv（Inky AI 模式动效，inky_mode_enabled
// 远端服务面）、anim_grow/learn/memorize/productivity + learn_confetti
// （Rive 启动页/Learn 动效，static_* 回退存在，Learn 后端门禁）、
// pdfnet/pdftron_*（vendored PDF 引擎）、ayp_youtube_player.html
// （vendored YouTube iframe）。
// res/font：GT America Mono/GT Flaire/ProximaSoft/Untitled Serif/EB
// Garamond/Inter/Roboto —— 品牌 UI 字体，许可专有；Harmony 用系统字体。
// res/anim|animator|interpolator|menu|layout|color|integers|dimens：
// vendored（Material checkbox/radio、fragment transitions、spen_recoil、
// qt_*/mini_pen_* S Pen、compat_*、notification_*、setting_qt_*）。
// feature_note__* 残余：content_manager/page 动作、jump_to、math_editor、
// selection_menu、empty_note、cropping、deselect、undo/redo、link_menu、
// note_deleted(→uc9 不可用弹窗)、text_only banner、image_too_large、
// phone_title 已移植（改名键）；gif_picker=Klipy、youtube/transcripts=服务、
// version_history/presence/view_only/finish_notes=后端协作、
// hwr_panel=MyScript iink（ADR-0645 同界）、inky=AI 服务、
// quick_tool=S Pen、download_failed/access_denied=同步、
// disconnect_stylus=蓝牙笔 —— 全部 fail-closed 有主。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};
const read = p => fs.readFileSync(p, 'utf8');

const strings = read('note/src/main/resources/base/element/string.json');
const recording = read('note/src/main/ets/core/adaptation/OriginalRecordingSourceBackend.ets');
const notePage = read('note/src/main/ets/ui/editor/NotePage.ets');
const selOverlay = read('note/src/main/ets/ui/components/SelectionOverlay.ets');
const adr = read('docs/migration/adr/ADR-1363-manifest-residual-axes.md');
const ev = read('docs/migration/evidence/phase-1428-manifest-residual-axes.md');

// --- 前台任务等价物已移植（RecordingForegroundService → continuousTask） ---
check('recording uses backgroundTaskManager continuous task',
  recording.includes('backgroundTaskManager') &&
  recording.includes('beginContinuousTask'));

// --- 一版 Manifest 组件无遗漏宿主 ---
check('note-unavailable dialog covers uc9 deleted path',
  notePage.includes('uc9'));
check('selection menu z-order/group/lock cluster ported (ADR-0645)',
  selOverlay.includes('SEND_TO_BACK') && selOverlay.includes('UNGROUP') &&
  selOverlay.includes('LOCK'));

// --- 后端/平台面 fail-closed 无漏出 ---
check('no view_only surface (version-history/shared-note mode)',
  !strings.includes('view_only'));
check('no inky AI surface or Rive runtime reference',
  !strings.includes('inky') && !fs.existsSync('note/src/main/resources/rawfile/inky_2026_v32.riv'));
check('no version_history surface (backend-gated)',
  !strings.includes('version_history_title'));
check('no hwr_panel method picker (MyScript iink boundary, ADR-0645)',
  !strings.includes('hwr_panel'));
check('no youtube import surface (backend transcript service)',
  !strings.includes('youtube_insert_failed'));
check('no S Pen quick-tool strings (vendored host absent)',
  !strings.includes('quick_tool_pen'));

// --- 裁决文书 ---
check('ADR-1363 adjudicates manifest + residual resource axes',
  adr.includes('AppUpgradeReceiver') && adr.includes('baseline') &&
  adr.includes('ui_designsystem__anim_'));
check('evidence doc records vendored font/raw boundary',
  ev.includes('pdftron') && ev.includes('ExportFileProvider'));

console.log(`TOTAL=${checks.length} FAILED=0`);
