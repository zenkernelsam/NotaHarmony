import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const desktop = 'C:/Users/Cisco He/Desktop/Notability/';
const readOriginal = path => fs.readFileSync(desktop + path, 'utf8');

const picker = read('note/src/main/ets/ui/components/ColorPicker.ets');
const vm = read('note/src/main/ets/ui/editor/EditorViewModel.ets');
const repo = read('note/src/main/ets/data/ToolRepositoryImpl.ets');
const stringsBase = read('note/src/main/resources/base/element/string.json');
const stringsZh = read('note/src/main/resources/zh_CN/element/string.json');

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };

// --- Original evidence anchors ----------------------------------------------------------
// The toolbox event vocabulary (rh9): add/delete/write/select for color wells.
const xg9 = readOriginal('decompiled_1.0.3/sources/defpackage/xg9.java');
const bh9 = readOriginal('decompiled_1.0.3/sources/defpackage/bh9.java');
const ah9 = readOriginal('decompiled_1.0.3/sources/defpackage/ah9.java');
const yg9 = readOriginal('decompiled_1.0.3/sources/defpackage/yg9.java');
const ti9 = readOriginal('decompiled_1.0.3/sources/defpackage/ti9.java');
const wj9 = readOriginal('decompiled_1.0.3/sources/defpackage/wj9.java');
const jm3 = readOriginal('decompiled_1.0.3/sources/defpackage/jm3.java');
const ys2 = readOriginal('decompiled_1.0.3/sources/defpackage/ys2.java');
const tb4 = readOriginal('decompiled_1.0.3/sources/defpackage/tb4.java');
const vb4 = readOriginal('decompiled_1.0.3/sources/defpackage/vb4.java');
const qb4 = readOriginal('decompiled_1.0.3/sources/defpackage/qb4.java');
const origStrings = readOriginal('decompiled_1.0.3/resources/res/values/strings.xml');

// Event payloads.
ok(xg9.includes('xg9(a6f a6fVar, int i, mv6 mv6Var)') &&
   xg9.includes('"OnAddColorClick('),
  'original OnAddColorClick(toolType, index, mv6) missing');
ok(bh9.includes('public final pb4 a') && bh9.includes('"OnDeleteColorClick('),
  'original OnDeleteColorClick(well) missing');
ok(ah9.includes('"OnColorWellValueChange(wellId="') &&
   ah9.includes(', wellIndex=') && ah9.includes(', newColor='),
  'original OnColorWellValueChange(wellId, wellIndex, newColor) missing');
ok(yg9.includes('yg9'), 'original OnBrushColorClick missing');
// ti9 dispatch: xg9 -> g0, bh9 -> z47, ah9 -> xh9, yg9 -> ku5.
ok(ti9.includes('rh9Var instanceof xg9') && ti9.includes('rh9Var instanceof bh9') &&
   ti9.includes('rh9Var instanceof ah9') && ti9.includes('rh9Var instanceof yg9'),
  'original well-event dispatch missing');
// wj9 case 17: the color wheel/editor writes the well — OnColorWellValueChange
// carries the editor color (kkf.c0) plus the well identity/index.
ok(wj9.includes('new ah9(p7fVar.c, kkf.c0(((iu1) obj).a), p7fVar.b)'),
  'original wheel->well write event missing');
// jm3/ys2: the '+' affordance dispatches OnAddColorClick; the per-tool menu
// dispatches OnDeleteColorClick(pb4).
ok(jm3.includes('new xg9(a6fVar, ((Integer) obj2).intValue(), (mv6) obj3)'),
  'original add-color dispatch missing');
ok(ys2.includes('new bh9(pb4Var)'), 'original delete-color dispatch missing');
// Storage: delete shifts trayIndex down (tb4) then deletes the row (vb4).
ok(tb4.includes('UPDATE FavoriteColorWellEntity SET trayIndex = trayIndex - 1 WHERE trayIndex > ? AND toolType = ?') &&
   vb4.includes('DELETE FROM `FavoriteColorWellEntity` WHERE `id` = ?'),
  'original well delete + reindex missing');
ok(qb4.includes('FavoriteColorWellEntity(id=') && qb4.includes('trayIndex='),
  'original FavoriteColorWellEntity fields missing');
ok(origStrings.includes('ui_tools__add_a_color') &&
   origStrings.includes('ui_tools__color_options') &&
   origStrings.includes('ui_tools__open_color_wheel') &&
   origStrings.includes('ui_tools__delete'),
  'original well-edit strings missing');

// --- Harmony anchors ----------------------------------------------------------------------
// VM: add writes the current brush color at the next tray slot (xg9 parity),
// write/remove reuse the Phase 532 repo paths (ah9/bh9 parity).
ok(vm.includes('async addFavoriteColorWell(): Promise<boolean>') &&
   vm.includes('repository.setFavoriteColor(this.activeToolType(), this.favoriteColors.length,') &&
   vm.includes('this.brushColor'),
  'addFavoriteColorWell missing');
ok(vm.includes('async setFavoriteColorWell(index: number, color: number)') &&
   vm.includes('async removeFavoriteColorWell(index: number)'),
  'well write/remove VM paths missing');
// Repo: upsert + shift-down delete (i8f/tb4 parity, already present).
ok(repo.includes('async setFavoriteColor(toolType: number, trayIndex: number, color: number)') &&
   repo.includes('UPDATE favorite_color_well SET tray_index = tray_index - 1 WHERE tray_index > ? AND tool_type = ?'),
  'favorite color well repo paths missing');
// UI: tap selects (yg9), long-press opens the well menu, '+' tile adds.
ok(picker.includes('bindContextMenu(this.buildWellMenu(index), ResponseType.LongPress)'),
  'well long-press menu missing');
ok(picker.includes("Text('+')") && picker.includes("$r('app.string.add_a_color')") &&
   picker.includes('this.viewModel.addFavoriteColorWell()'),
  'add-color tile missing');
ok(picker.includes("$r('app.string.well_set_current_color')") &&
   picker.includes('this.viewModel.setFavoriteColorWell(index, this.viewModel.brushColor)') &&
   picker.includes("$r('app.string.delete')") &&
   picker.includes('this.viewModel.removeFavoriteColorWell(index)'),
  'well menu actions missing');
// Lease guard: every new callback fails closed under the photo-import lease.
ok(/onClick\(\(\) => \{\s*if \(this\.photoImportLeaseActive\)[\s\S]*?addFavoriteColorWell/.test(picker) &&
   /buildWellMenu[\s\S]*?photoImportLeaseActive/.test(picker),
  'well affordances must respect the photo-import lease');
for (const name of ['add_a_color', 'well_set_current_color']) {
  ok(stringsBase.includes(`"name": "${name}"`) && stringsZh.includes(`"name": "${name}"`),
    `string ${name} missing in a locale`);
}

// --- Executable model: well add/write/delete ----------------------------------------------
// favorite_color_well rows keyed (toolType, trayIndex), dense order.
function addWell(wells, color) { return [...wells, color]; }
function writeWell(wells, index, color) {
  return wells.map((c, i) => i === index ? color : c);
}
// tb4: shift trayIndex down past the removed slot, then delete.
function deleteWell(wells, index) {
  return wells.filter((_, i) => i !== index);
}
let wells = [-16777216, -15260469, -2011583]; // Harmony default pen wells
wells = addWell(wells, -65536);
assert.deepEqual(wells, [-16777216, -15260469, -2011583, -65536]); checks++;
wells = writeWell(wells, 1, -256);
assert.deepEqual(wells, [-16777216, -256, -2011583, -65536]); checks++;
wells = deleteWell(wells, 0);
assert.deepEqual(wells, [-256, -2011583, -65536]); checks++; // dense reindex
// Add after delete lands at the new end (trayIndex = length).
wells = addWell(wells, -16744448);
assert.deepEqual(wells, [-256, -2011583, -65536, -16744448]); checks++;

console.log(`D02_ORIGINAL_COLOR_WELL_EDIT_OK TOTAL=${checks} FAILED=0`);
