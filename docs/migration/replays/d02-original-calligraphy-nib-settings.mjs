// Phase 1390 — 1.4.2 CALLIGRAPHY 凿尖设置面板 + 每工具 STYLE 门控修正。
// 原版证据（decompiled_1.4.2）：
//   k31.java:66-82  — 工具 settings 集由接口判定：q92→COLOR、fgg→WIDTH、
//                     n5h→STYLE、sri→CALLIGRAPHY、wsi.e()→tool 专属性
//                     （SHAPE_KIND/TAPE_PATTERN/SELECTION_MODE）。
//   csi/wri        — 仅 PEN/HIGHLIGHTER 实现 n5h → 仅它们显 STYLE 行；
//                     sri(CALLIGRAPHY)/psi(SHAPE)/esi(PENCIL)/jsi(REVIEW) 均无。
//   ij1.java       — 凿尖面板：角度滑块 o6k.a0(15, ju7(-60,60,1)) = -60..60 步15（9 档），
//                     扁率 0.00..0.95 步0.05（20 档）+ Reset，Stabilization 开关。
//   q6i.java:117   — 角度显示 = Math.toDegrees(nibAngle - π/2)（相对竖直偏移）。
//   pxi.java       — 三 handler：wp(int°)=angle、is5(float)=flatness、g0c(bool)=stabilization。
//   aj1.c          — CalligraphySelection(nibAngle, nibFlatness, nibStabilization)。
// 断言：
//   supportsBrushStyleControls() 仅 PEN/HIGHLIGHTER（n5h 校验）；
//   CALLIGRAPHY 激活时 EditorToolbar 改显 CalligraphyNibPanel；
//   calligraphyStabilization 持久化（ToolStateEntity.stabilization）；
//   RenderSpec.stabilization → StrokeSession.stabilizationActive → 位置 EMA 平滑。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const VM = 'note/src/main/ets/ui/editor/EditorViewModel.ets';
const ST = 'note/src/main/ets/core/model/StrokeTypes.ets';
const SS = 'note/src/main/ets/rendering/StrokeSession.ets';
const TB = 'note/src/main/ets/ui/editor/EditorToolbar.ets';
const PANEL = 'note/src/main/ets/ui/components/CalligraphyNibPanel.ets';
const STR_BASE = 'note/src/main/resources/base/element/string.json';
const STR_ZH = 'note/src/main/resources/zh_CN/element/string.json';

const vm = readFileSync(VM, 'utf8');
const st = readFileSync(ST, 'utf8');
const ss = readFileSync(SS, 'utf8');
const tb = readFileSync(TB, 'utf8');
const panel = readFileSync(PANEL, 'utf8');
const strBase = readFileSync(STR_BASE, 'utf8');
const strZh = readFileSync(STR_ZH, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// === 1. Per-tool STYLE gating (k31.E / n5h) ===
check(/supportsBrushStyleControls\(\): boolean/.test(vm),
  'supportsBrushStyleControls() exists');
{
  const m = vm.match(/supportsBrushStyleControls\(\): boolean \{([\s\S]*?)\n  \}/);
  check(m !== null, 'supportsBrushStyleControls body');
  const body = m[1];
  check(/ToolType\.PEN/.test(body) && /ToolType\.HIGHLIGHTER/.test(body),
    'STYLE row limited to PEN + HIGHLIGHTER (n5h implementors)');
  check(!/ToolType\.CALLIGRAPHY/.test(body) && !/ToolType\.SHAPE/.test(body) &&
    !/ToolType\.PENCIL/.test(body) && !/ToolType\.REVIEW/.test(body),
    'STYLE row excludes CALLIGRAPHY/SHAPE/PENCIL/REVIEW (no n5h)');
}
// The toolbar gates the brush-style row on supportsBrushStyleControls, not brush controls.
check(/supportsBrushStyleControls\(\)[\s\S]{0,240}StyleButton/.test(tb),
  'toolbar STYLE row gated on supportsBrushStyleControls');

// === 2. Calligraphy nib panel surface ===
check(/CalligraphyNibPanel/.test(tb) && /isCalligraphyActive\(\)[\s\S]{0,80}CalligraphyNibPanel/
  .test(tb), 'CALLIGRAPHY active → CalligraphyNibPanel replaces style row');
check(/import \{ CalligraphyNibPanel \}/.test(tb), 'EditorToolbar imports CalligraphyNibPanel');

// Angle slider: -60..60 step 15 (ij1 a = a0(15, ju7(-60,60,1))).
check(/NIB_ANGLE_MIN_DEG: number = -60/.test(panel) &&
  /NIB_ANGLE_MAX_DEG: number = 60/.test(panel) &&
  /NIB_ANGLE_STEP_DEG: number = 15/.test(panel),
  'angle slider detents -60..60 step 15 (9 positions)');
check(/nibAngle - Math\.PI \/ 2|calligraphyNibAngle - Math\.PI \/ 2/.test(panel) &&
  /\* 180 \/ Math\.PI/.test(panel),
  'angle displayed as degrees offset from vertical (toDegrees(nibAngle-π/2))');
check(/Math\.PI \/ 2 \+ .* \* Math\.PI \/ 180|offsetDeg \* Math\.PI \/ 180/.test(panel),
  'angle written back as π/2 + radians(offset)');
check(/setCalligraphyNibAngle/.test(panel), 'angle slider commits via setCalligraphyNibAngle');

// Flatness slider: 0.00..0.95 step 0.05 (ij1 b, 20 positions) + Reset to 0.75.
check(/NIB_FLATNESS_MIN: number = 0/.test(panel) &&
  /NIB_FLATNESS_MAX: number = 0\.95/.test(panel) &&
  /NIB_FLATNESS_STEP: number = 0\.05/.test(panel),
  'flatness slider detents 0.00..0.95 step 0.05 (20 positions)');
check(/setCalligraphyNibFlatness/.test(panel), 'flatness slider commits via setCalligraphyNibFlatness');
check(/app\.string\.reset/.test(panel) && /setCalligraphyNibFlatness\(DEFAULT_FLATNESS\)/.test(panel),
  'Reset restores flatness to aj1() default 0.75');

// Stabilization toggle (ij1 c(label, z, pxi) → g0c bool).
check(/app\.string\.stabilization/.test(panel) && /ToggleType\.Switch/.test(panel) &&
  /setCalligraphyStabilization/.test(panel),
  'Stabilization toggle commits via setCalligraphyStabilization');
check(/calligraphyStabilization/.test(panel), 'panel binds calligraphyStabilization');

// === 3. ViewModel state + mutators ===
check(/calligraphyStabilization: boolean = true/.test(vm),
  'calligraphyStabilization defaults true (zmb seed =1)');
check(/calligraphyStabilization =[\s\S]{0,170}stabilization !== 0/.test(vm),
  'applyActiveState loads stabilization (null/!=0 → on)');
check(/setCalligraphyNibAngle\(angleRadians: number\)[\s\S]{0,160}isCalligraphyActive/
  .test(vm), 'setCalligraphyNibAngle guarded by isCalligraphyActive');
check(/setCalligraphyNibFlatness\(flatness: number\)[\s\S]{0,160}isCalligraphyActive/
  .test(vm), 'setCalligraphyNibFlatness guarded by isCalligraphyActive');
check(/setCalligraphyStabilization\(enabled: boolean\)[\s\S]{0,120}isCalligraphyActive/
  .test(vm), 'setCalligraphyStabilization guarded by isCalligraphyActive');
check(/state\.stabilization = enabled \? 1 : 0/.test(vm),
  'stabilization persisted as INTEGER 0/1 (ToolStateEntity.stabilization)');

// === 4. RenderSpec → StrokeSession ===
check(/stabilization\?:\s*boolean \| null/.test(st),
  'RenderSpec carries optional stabilization (transient, not in ink format)');
check(/stabilization: this\.currentTool === ToolType\.CALLIGRAPHY/
  .test(vm), 'getRenderSpec emits stabilization only for CALLIGRAPHY');
check(/stabilizationActive = spec\.stabilization === true/.test(ss),
  'beginStroke enables positional stabilizer only when stabilization===true');
check(/stabilizePosition/.test(ss) && /STABILIZATION_ALPHA/.test(ss),
  'StrokeSession.stabilizePosition EMA exists (positional, not force)');
check(/position: stabilized/.test(ss),
  'real committed points go through stabilizePosition');

// === 5. Strings ===
for (const [file, src, lang] of [[STR_BASE, strBase, 'base'], [STR_ZH, strZh, 'zh_CN']]) {
  for (const key of ['calligraphy_angle', 'calligraphy_flatness', 'stabilization', 'reset']) {
    check(new RegExp(`"name":\\s*"${key}"`).test(src), `${lang} has ${key}`);
  }
}
check(strBase.includes('"value": "Angle: %d°"'), 'base calligraphy_angle = Angle: %d°');
check(strBase.includes('"value": "Flatness: %.2f"'), 'base calligraphy_flatness = Flatness: %.2f');
check(strBase.includes('"value": "Stabilization"'), 'base stabilization = Stabilization');
check(strBase.includes('"value": "Reset"'), 'base reset = Reset');

// === 6. Numeric sanity: original angle detents ↔ radians ===
{
  const deg2rad = d => Math.PI / 2 + d * Math.PI / 180;
  assert(Math.abs(deg2rad(0) - Math.PI / 2) < 1e-9, 'offset 0° → nibAngle π/2 (default)');
  assert(Math.abs(deg2rad(60) - (Math.PI / 2 + Math.PI / 3)) < 1e-9, 'offset 60° → 150°');
  assert(Math.abs(deg2rad(-60) - (Math.PI / 2 - Math.PI / 3)) < 1e-9, 'offset -60° → 30°');
  // 9 detents: -60,-45,...,+60.
  const detents = [];
  for (let d = -60; d <= 60; d += 15) detents.push(d);
  assert(detents.length === 9, 'angle slider has 9 discrete positions');
  // flatness 20 detents 0.00..0.95.
  const fl = [];
  for (let i = 0; i <= 19; i++) fl.push(+(i * 0.05).toFixed(2));
  assert(fl.length === 20 && Math.abs(fl[19] - 0.95) < 1e-9, 'flatness 20 positions to 0.95');
  n += 5;
}

console.log(`d02-original-calligraphy-nib-settings OK — ${n} checks`);
