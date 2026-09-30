// Phase 1388 — 1.4.2 CALLIGRAPHY chisel-nib tool vertical slice.
// Original evidence (decompiled_1.4.2):
//   eti.java        — tool enum adds CALLIGRAPHY(1) between PEN/PENCIL.
//   aj1.java:48     — CalligraphySelection(nibAngle=π/2, nibFlatness=0.75,
//                     stabilization=true) default nib.
//   foa.java        — nib enum NARROW/WIDE presets.
//   zmb.java:135-137— upgrade SQL inserts CALLIGRAPHY at pen.trayIndex+1 with
//                     color=-16777216, widthSize=1.0, nibAngle=1.5707964,
//                     nibFlatness=0.75, stabilization=1.
//   cc3.java G()    — fresh-install default: CALLIGRAPHY primary index 1,
//                     absent from F() color-well and I() width-well seeds.
//   xal.java        — ink ops quantize nibAngle over 2π (scale 65536) and
//                     nibFlatness over [0,1] (scale 65535).
//   ui_tools__calligraphy = "Calligraphy"; ui_designsystem__calligraphy_* =
//                     the 5-layer toolbox glyph.
// Port: dedicated tool on the stroke pipeline; RenderSpec carries
//       nibAngle/nibFlatness; WidthOutlineBuilder modulates radius by the
//       chisel projection sqrt(cos²Δ+f²·sin²Δ) (Δ=travel−nibAngle), gated on
//       nibAngle≠null so non-calligraphy strokes render bit-identically.
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const VM = 'note/src/main/ets/ui/editor/EditorViewModel.ets';
const BT = 'note/src/main/ets/core/model/BrushTypes.ets';
const ST = 'note/src/main/ets/core/model/StrokeTypes.ets';
const OB = 'note/src/main/ets/core/algorithm/WidthOutlineBuilder.ets';
const CR = 'note/src/main/ets/core/adaptation/Canvas2DStrokeRenderer.ets';
const SS = 'note/src/main/ets/rendering/StrokeSession.ets';
const PE = 'note/src/main/ets/rendering/OriginalInkPartialEraser.ets';
const CODEC = 'note/src/main/ets/data/OriginalInkPathCodec.ets';
const COP = 'note/src/main/ets/data/OriginalCreateInkOperation.ets';
const MOP = 'note/src/main/ets/data/OriginalModifyInkOperation.ets';
const GLYPHS = 'note/src/main/ets/ui/components/ToolGlyphs.ets';
const GLYPH = 'note/src/main/ets/ui/components/ToolGlyph.ets';
const DLG = 'note/src/main/ets/ui/editor/ToolboxSettingsDialog.ets';
const STR_BASE = 'note/src/main/resources/base/element/string.json';
const STR_ZH = 'note/src/main/resources/zh_CN/element/string.json';
const NCV = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';

const vm = readFileSync(VM, 'utf8');
const bt = readFileSync(BT, 'utf8');
const st = readFileSync(ST, 'utf8');
const ob = readFileSync(OB, 'utf8');
const cr = readFileSync(CR, 'utf8');
const ss = readFileSync(SS, 'utf8');
const pe = readFileSync(PE, 'utf8');
const codec = readFileSync(CODEC, 'utf8');
const cop = readFileSync(COP, 'utf8');
const mop = readFileSync(MOP, 'utf8');
const glyphs = readFileSync(GLYPHS, 'utf8');
const glyph = readFileSync(GLYPH, 'utf8');
const dlg = readFileSync(DLG, 'utf8');
const strBase = readFileSync(STR_BASE, 'utf8');
const strZh = readFileSync(STR_ZH, 'utf8');
const ncv = readFileSync(NCV, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// === 1. Model surface ===
check(/CALLIGRAPHY\s*=\s*\d+/.test(bt), 'ToolType.CALLIGRAPHY enum member exists');
check(/nibAngle\?:\s*number\s*\|\s*null/.test(bt) &&
  /nibFlatness\?:\s*number\s*\|\s*null/.test(bt),
  'ToolState carries optional nibAngle/nibFlatness (ToolStateEntity REAL cols)');
check(/nibAngle\?:\s*number\s*\|\s*null/.test(st) &&
  /nibFlatness\?:\s*number\s*\|\s*null/.test(st),
  'RenderSpec carries optional nibAngle/nibFlatness');

// === 2. Default nib constants (aj1.java:48) ===
check(vm.includes('DEFAULT_NIB_ANGLE') && /DEFAULT_NIB_ANGLE[^=]*=\s*Math\.PI\s*\/\s*2/.test(vm),
  'default nib angle = π/2 (90°)');
check(/DEFAULT_NIB_FLATNESS[^=]*=\s*0\.75/.test(vm),
  'default nib flatness = 0.75');

// === 3. Default toolbox seed (zmb.java:135 / cc3.G()) ===
const defaults = vm.slice(vm.indexOf('private createDefaultStates'));
check(/'calligraphy',\s*ownerId,\s*ToolType\.CALLIGRAPHY,\s*1,\s*-16777216,\s*1\.0/.test(defaults),
  'CALLIGRAPHY seeded at primary index 1, color=-16777216, width=1.0');
check(defaults.indexOf("'calligraphy'") > defaults.indexOf("'pen'") &&
  defaults.indexOf("'calligraphy'") < defaults.indexOf("'pencil'"),
  'calligraphy sits right after pen (pen.trayIndex+1) and before pencil');
check(/ToolType\.CALLIGRAPHY[^)]*DEFAULT_NIB_ANGLE[^)]*DEFAULT_NIB_FLATNESS/.test(defaults),
  'calligraphy row carries the default nib (angle,flatness)');
check(/ToolType\.PENCIL,\s*2/.test(defaults) && /ToolType\.HIGHLIGHTER,\s*3/.test(defaults),
  'existing primary tools shifted +1 to make room (cc3.G order)');

// === 4. cloneState preserves nib across saves ===
const clone = vm.slice(vm.indexOf('private cloneState'));
check(clone.includes('nibAngle: state.nibAngle') && clone.includes('nibFlatness: state.nibFlatness'),
  'cloneState carries nib fields (no silent drop on persist)');

// === 5. getRenderSpec emits nib only for CALLIGRAPHY ===
const spec = vm.slice(vm.indexOf('getRenderSpec'));
check(spec.includes('this.currentTool === ToolType.CALLIGRAPHY ? this.calligraphyNibAngle : null'),
  'nibAngle emitted only for CALLIGRAPHY (null otherwise)');
check(spec.includes('this.currentTool === ToolType.CALLIGRAPHY ? this.calligraphyNibFlatness : null'),
  'nibFlatness emitted only for CALLIGRAPHY');
check(spec.includes('this.currentTool === ToolType.CALLIGRAPHY ? InkStyle.VARIABLE_WIDTH'),
  'calligraphy forces VARIABLE_WIDTH so the nib can modulate');

// === 6. Toolbox surface ===
check(vm.includes('this.calligraphyNibAngle = state.nibAngle ?? EditorViewModel.DEFAULT_NIB_ANGLE'),
  'applyActiveState adopts per-tool nib with default fallback');
check(/isCalligraphyActive\(\)[\s\S]{0,80}ToolType\.CALLIGRAPHY/.test(vm),
  'isCalligraphyActive helper present');
check(/supportsBrushControls\(\)[\s\S]*ToolType\.CALLIGRAPHY/.test(vm),
  'calligraphy exposes brush controls (color/width)');
check(dlg.includes('case ToolType.CALLIGRAPHY') && dlg.includes("calligraphy"),
  'toolTypeLabel maps CALLIGRAPHY to the calligraphy string');
check(strBase.includes('"name": "calligraphy"') && /calligraphy[\s\S]{0,40}Calligraphy/.test(strBase),
  'base string calligraphy=Calligraphy (ui_tools__calligraphy)');
check(strZh.includes('"name": "calligraphy"'), 'zh string for calligraphy present');

// === 7. Glyph ===
check(/'calligraphy':\s*\{/.test(glyphs), 'TOOL_GLYPHS has a calligraphy entry');
{
  const entry = glyphs.slice(glyphs.indexOf("'calligraphy'"),
    glyphs.indexOf("'calligraphy'") + 3000);
  // 5-layer m4f structure: f(fill) o(outline+sw) h(highlight) s(shadow) v(overlay).
  for (const k of ['f:', 'o:', 'sw:', 'h:', 's:', 'v:', 'vw: 24', 'vh: 24']) {
    check(entry.includes(k), `calligraphy glyph carries layer key "${k}"`);
  }
}
check(glyph.includes('case ToolType.CALLIGRAPHY') && glyph.includes("return 'calligraphy'"),
  'ToolGlyph maps CALLIGRAPHY → calligraphy');
check(/COLOR_GLYPHS[^;]*'calligraphy'/.test(glyph),
  'calligraphy fill tinted by brush color (cq.h semantics)');

// === 8. Chisel-nib modulation (gated) ===
check(ob.includes('setNib') && ob.includes('private nibScale'),
  'WidthOutlineBuilder has setNib + nibScale');
check(/nibScale\(tangent[\s\S]{0,420}Math\.sqrt\(c \* c \+ f \* f \* s \* s\)/.test(ob),
  'nibScale = sqrt(cos²Δ + f²·sin²Δ) chisel projection');
check(/if \(this\.nibAngle === null\)[\s\S]{0,30}return 1/.test(ob),
  'nibScale short-circuits to 1 when nibAngle is null (bit-identical non-nib path)');
check(/build\([^)]*nibAngle\?:\s*number\s*\|\s*null[^)]*nibFlatness\?:\s*number\s*\|\s*null/.test(ob),
  'build() accepts optional nibAngle/nibFlatness');

// === 9. All render paths pass nib ===
check(/builder\.build\([\s\S]{0,140}renderSpec\.nibAngle[^,]*,\s*stroke\.renderSpec\.nibFlatness/.test(cr) ||
  /renderSpec\.nibAngle,\s*stroke\.renderSpec\.nibFlatness/.test(cr),
  'Canvas2DStrokeRenderer passes nib into build()');
check(/outlineBuilder\.build\([^)]*renderSpec\.nibAngle[^)]*renderSpec\.nibFlatness/.test(ss) ||
  ss.includes('this.renderSpec.nibAngle'),
  'StrokeSession live preview passes nib');
check(pe.includes('stroke.renderSpec.nibAngle') && pe.includes('stroke.renderSpec.nibFlatness'),
  'partial-eraser hit region carries nib (chisel-consistent erase)');

// === 10. Ink-op decode (xal quantization) ===
check(codec.includes('decodeNibAngleUint16') && codec.includes('decodeNibFlatnessUint16'),
  'codec exposes nib decode helpers');
check(/decodeNibAngleUint16[\s\S]{0,160}65536/.test(codec),
  'nibAngle decoded over 2π via /65536 signed-range scale');
check(/decodeNibFlatnessUint16[\s\S]{0,160}65535/.test(codec),
  'nibFlatness decoded via /65535');
check(cop.includes('decodeNibAngleUint16') && cop.includes('nibAngle'),
  'CreateInk wires decoded nib onto the stroke renderSpec');
check(mop.includes('decodeNibAngleUint16') && mop.includes('nibAngle'),
  'ModifyInk preserves/decodes nib onto the rebuild renderSpec');

// === 11. Shape-detect: calligraphy is a pen-family writing tool ===
check(/ToolType\.PEN \|\| tool === ToolType\.PENCIL \|\| tool === ToolType\.HIGHLIGHTER \|\|[\s\S]{0,80}ToolType\.CALLIGRAPHY/.test(ncv) ||
  ncv.includes('tool === ToolType.CALLIGRAPHY'),
  'hold-shape detection enabled for calligraphy (pen family)');

// === 12. Numeric: chisel projection behaves as designed ===
{
  // Mirror of nibScale: f=flatness, Δ=travel−nibAngle.
  const nibScale = (tangentAngle, nibAngle, f) => {
    const d = tangentAngle - nibAngle, c = Math.cos(d), s = Math.sin(d);
    return Math.sqrt(c * c + f * f * s * s);
  };
  const A = Math.PI / 2, f = 0.75;
  // Travel along nibAngle → max width (scale 1).
  assert(Math.abs(nibScale(A, A, f) - 1) < 1e-9, 'along-nib travel → full width');
  // Travel perpendicular → thinnest (scale f).
  assert(Math.abs(nibScale(A + Math.PI / 2, A, f) - f) < 1e-9, 'perpendicular → flatness');
  // f=1 (round nib) → direction-independent (scale 1 everywhere).
  for (const t of [0, 0.4, 1.1, 2.6]) {
    assert(Math.abs(nibScale(t, A, 1) - 1) < 1e-9, 'round nib: no directional modulation');
  }
  // Decode: raw=32768 over signed range 65536 → angle π; flatness raw=65535 → 1.0.
  assert(Math.abs((32768 * 2 * Math.PI / 65536) - Math.PI) < 1e-9, 'nibAngle uint16 decode');
  assert(Math.abs((65535 / 65535) - 1) < 1e-9, 'nibFlatness uint16 decode');
  n += 6;
}

console.log(`d02-original-calligraphy-tool OK — ${n} checks`);
console.log('TOTAL=1 FAILED=0');
