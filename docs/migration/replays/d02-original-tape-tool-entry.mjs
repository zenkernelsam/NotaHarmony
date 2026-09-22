// Phase 584 — original tape tool entry: REVIEW in the default toolbox.
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   a6f.java — tool enum: PEN=0 … LASER=9(R), REVIEW=10(S), RULER=11, ZOOM=12.
//   rz1.java:1075 — secondary tray defaults:
//     u5f(10,1,POINTER,0), u5f(0,1,LASER,1,w31(-1754827,15f,…)),
//     u5f(0,1,ZOOM,2), u5f(0,1,REVIEW,3,w31(-1706497,36f,null,0,1,0)),
//     u5f(0,1,RULER,4) — REVIEW sits at secondary index 3 with
//     color=-1706497, width=36f, colorWell=0, widthWell=1, tapePattern=0.
//   w31.java toString — BrushState(color,widthSize,style,
//     selectedColorWellIndex,selectedWidthSizeWellIndex,tapePattern);
//     tapePattern=0 ↔ TapePattern.STRIPES (i16 defaults to ife.STRIPES).
//   dm2 — tapePattern only validates with tool=TAPE on CreateInkOp.
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const VM = 'note/src/main/ets/ui/editor/EditorViewModel.ets';
const DIALOG = 'note/src/main/ets/ui/editor/ToolboxSettingsDialog.ets';
const REPO = 'note/src/main/ets/data/ToolRepositoryImpl.ets';

const vm = readFileSync(VM, 'utf8');
const dialog = readFileSync(DIALOG, 'utf8');
const repo = readFileSync(REPO, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- Default tool state (rz1:1075 / w31) ---
const defaults = vm.slice(vm.indexOf('private createDefaultStates'));
check(/'tape',\s*ownerId,\s*ToolType\.REVIEW,\s*3,\s*-1706497,\s*36/.test(defaults),
  'REVIEW seeded at secondary index 3 with color -1706497 width 36');
check(defaults.indexOf("ToolType.REVIEW") >
  defaults.indexOf("TRAY_TYPE_SECONDARY"),
  'REVIEW declared after the LASER secondary row');
check(/ToolType\.REVIEW,\s*3[^)]*TRAY_TYPE_SECONDARY/.test(defaults) ||
  defaults.includes('TRAY_TYPE_SECONDARY, TapePattern.STRIPES'),
  'REVIEW is a secondary-tray tool with STRIPES default pattern');
check(/TapePattern\.STRIPES,\s*0,\s*1/.test(defaults),
  'original w31 wells: colorWell 0, widthWell 1 (the 36f middle well)');

// --- createState carries tapePattern + well indices ---
const createState = vm.slice(vm.indexOf('private createState'));
check(createState.includes('tapePattern?: TapePattern'), 'createState accepts tapePattern');
check(createState.includes('tapePattern: tapePattern ?? null'),
  'tapePattern persisted on the ToolState');
check(createState.includes('selectedWidthWellIndex: widthWellIndex') &&
  createState.includes('selectedColorWellIndex: colorWellIndex'),
  'original well indices plumbed');

// --- Render spec (dm2: tapePattern only with TAPE) ---
const spec = vm.slice(vm.indexOf('getRenderSpec'));
check(spec.includes('this.currentTool === ToolType.REVIEW'),
  'tapePattern emitted only for REVIEW');
check(spec.includes('this.activeTapePattern'), 'active pattern flows into the spec');
check(/tapePattern:\s*this\.currentTool === ToolType\.REVIEW\s*\?\s*\n?\s*this\.activeTapePattern\s*:\s*undefined/
  .test(spec), 'non-REVIEW tools get undefined tapePattern');

// --- Active state + controls ---
check(vm.includes('this.activeTapePattern = state.tapePattern ?? TapePattern.STRIPES'),
  'applyActiveState adopts the row pattern (w31.f), STRIPES fallback');
check(vm.includes('activeTapePattern: TapePattern = TapePattern.STRIPES'),
  'session default = STRIPES (ife.STRIPES parity)');
check(/ToolType\.HIGHLIGHTER\s*\|\|\s*this\.currentTool === ToolType\.REVIEW/.test(vm),
  'supportsBrushControls includes REVIEW (5 color wells + 3 widths)');

// --- Toolbox label ---
check(dialog.includes("case ToolType.REVIEW: return $r('app.string.tape_tool')"),
  'toolbox settings labels REVIEW as Tape');

// --- Seeded wells exist for REVIEW ---
check(repo.includes('{ toolType: ToolType.REVIEW, values: [-1706497, -672330, -6303021, -11872, -2238485] }'),
  'original 5 color wells seeded');
check(repo.includes('{ toolType: ToolType.REVIEW, values: [12.0, 36.0, 64.0] }'),
  'original 3 width wells seeded');

console.log(`D02_ORIGINAL_TAPE_TOOL_ENTRY_OK TOTAL=${n} FAILED=0`);
