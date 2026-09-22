// Phase 572 — original laser pointer (a6f.R / zt6 / xt6 / yt6 / rz1.r / cu6).
// Original semantics decoded from decompiled_1.0.3:
//   rz1.r():  LASER lives in the secondary tray at index 1, default color
//             -1754827, single 15pt width well, 4 color wells
//             (-1754827, -14776091, -12345273, -141259).
//   cu6.i:    laser_preferences.show_tail default true.
//   xt6:      down/move only update render state — no persisted stroke.
//   yt6:      on up, fade coroutine waits 500ms then runs 31 frames × 16ms;
//             the visible contract is an opaque mark lingering ~1s then
//             clearing (the original fades the *other* alpha field).
//   ft0 22:   tail = round-cap/join polyline (tailAlpha), pointer = filled
//             circle radius width/2 (pointerAlpha).
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const LASER = 'note/src/main/ets/core/adaptation/OriginalLaserPointer.ets';
const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const VM = 'note/src/main/ets/ui/editor/EditorViewModel.ets';
const STORE = 'note/src/main/ets/data/EditorSettingsStore.ets';
const REPO = 'note/src/main/ets/data/ToolRepositoryImpl.ets';
const TYPES = 'note/src/main/ets/core/model/BrushTypes.ets';
const TOOLBAR = 'note/src/main/ets/ui/editor/EditorToolbar.ets';
const TOOLBOX = 'note/src/main/ets/ui/editor/ToolboxSettingsDialog.ets';
const STR_EN = 'note/src/main/resources/base/element/string.json';
const STR_ZH = 'note/src/main/resources/zh_CN/element/string.json';

const laser = readFileSync(LASER, 'utf8');
const canvas = readFileSync(CANVAS, 'utf8');
const vm = readFileSync(VM, 'utf8');
const store = readFileSync(STORE, 'utf8');
const repo = readFileSync(REPO, 'utf8');
const types = readFileSync(TYPES, 'utf8');
const toolbar = readFileSync(TOOLBAR, 'utf8');
const toolbox = readFileSync(TOOLBOX, 'utf8');
const strEn = readFileSync(STR_EN, 'utf8');
const strZh = readFileSync(STR_ZH, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- Adaptation layer: constants and state machine ---
check(laser.includes('ORIGINAL_LASER_COLOR: number = -1754827'), 'default color');
check(laser.includes('ORIGINAL_LASER_WIDTH_PT: number = 15.0'), 'default width 15pt');
check(laser.includes('ORIGINAL_LASER_FADE_DELAY_MS: number = 500'), 'fade delay 500ms');
check(laser.includes('ORIGINAL_LASER_FADE_FRAMES: number = 31'), '31 fade frames');
check(laser.includes('ORIGINAL_LASER_FRAME_MS: number = 16'), '16ms frame');
check(laser.includes('ORIGINAL_LASER_DEFAULT_SHOW_TAIL: boolean = true'), 'show_tail default true');
check(laser.includes('class OriginalLaserSession'), 'session class');
check(laser.includes('interface OriginalLaserRenderState'), 'render state');
check(laser.includes('applyFadeFrame'), 'fade frame stepper');
check(laser.includes('pointerAlpha') && laser.includes('tailAlpha'), 'dual alpha fields');

// --- ToolType + default tray state ---
check(/LASER = 8/.test(types), 'ToolType.LASER');
check(vm.includes("createState('laser'"), 'default laser state');
check(vm.includes('ToolType.LASER, 1, -1754827, 15'), 'laser defaults: index/color/width');
check(vm.includes('TRAY_TYPE_SECONDARY'), 'secondary tray');
check(vm.includes('isLaserActive'), 'VM laser check');
check(vm.includes('supportsColorControls'), 'laser color wells enabled');
check(vm.includes('laserShowTail'), 'VM tail pref');
check(vm.includes('setLaserShowTail'), 'VM tail setter');
// Laser must not load brush width wells (single fixed 15pt).
check(vm.includes('this.widthWells = this.supportsBrushControls() ?'), 'laser skips width wells');

// --- Settings persistence ---
check(store.includes("LASER_SHOW_TAIL_KEY: string = 'laserShowTail'"), 'store key');
check(store.includes('getLaserShowTail'), 'store getter');
check(store.includes('saveLaserShowTail'), 'store setter');
check(store.includes('DEFAULT_LASER_SHOW_TAIL: boolean = true'), 'store default true');

// --- Repository wells ---
check(repo.includes('ToolType.LASER, values: [-1754827, -14776091, -12345273, -141259]'),
  '4 laser color wells');
check(repo.includes('ToolType.LASER, values: [15.0]'), 'single 15pt width well');

// --- Canvas integration: transient only, never persisted ---
check(canvas.includes('OriginalLaserSession'), 'canvas session field');
check(canvas.includes('isLaserActive()'), 'canvas laser branch');
check(canvas.includes('scheduleLaserFade'), 'fade scheduling');
check(canvas.includes('cancelLaserFade'), 'fade cancellation');
check(canvas.includes('renderLaserOverlay'), 'transient render pass');
check(canvas.includes('laserSession.clear()'), 'session cleanup');
// Laser branch returns before stroke-session creation — no StrokeSession,
// no undo push, no persist call inside the laser paths.
const laserDown = canvas.slice(canvas.indexOf('isLaserActive()'));
check(laserDown.indexOf('return;') < laserDown.indexOf('makeRenderSpec'),
  'laser down returns before stroke creation');
check(!laserDown.slice(0, laserDown.indexOf('makeRenderSpec')).includes('undoRedo'),
  'laser path pushes no undo action');

// --- Toolbar + toolbox ---
check(toolbar.includes('isLaserActive()'), 'toolbar laser branch');
check(toolbar.includes('laser_tail_label') && toolbar.includes('laser_no_tail_label'),
  'tail segmented control');
check(toolbar.includes('supportsColorControls()'), 'color button supports laser');
check(toolbox.includes('ToolType.LASER: return $r'), 'toolbox label');

// --- Strings (EN verbatim + zh) ---
for (const k of ['"laser"', '"laser_tail_label"', '"laser_no_tail_label"',
  '"laser_tail_mode"', '"laser_no_tail_mode"']) {
  check(strEn.includes(`"name": ${k}`) || strEn.includes(`"name": ${k.replace(/"/g, '"')}`),
    `en string ${k}`);
  check(strZh.includes(`"name": ${k}`), `zh string ${k}`);
}
check(strEn.includes('"value": "No Tail"'), 'en No Tail verbatim');
check(strEn.includes('"value": "Tail mode"'), 'en Tail mode verbatim');
check(strEn.includes('"value": "No tail mode"'), 'en No tail mode verbatim');

console.log(`D02_ORIGINAL_LASER_POINTER_REPLAY_OK TOTAL=${n} FAILED=0`);
