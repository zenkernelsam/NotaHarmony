import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const desktop = 'C:/Users/Cisco He/Desktop/Notability/';
const readOriginal = path => fs.readFileSync(desktop + path, 'utf8');

const ddl = read('note/src/main/ets/data/DatabaseHelper.ets');
const dbMgr = read('note/src/main/ets/data/DatabaseManager.ets');
const brush = read('note/src/main/ets/core/model/BrushTypes.ets');
const iface = read('note/src/main/ets/data/RepositoryInterfaces.ets');
const repo = read('note/src/main/ets/data/ToolRepositoryImpl.ets');
const vm = read('note/src/main/ets/ui/editor/EditorViewModel.ets');
const toolbar = read('note/src/main/ets/ui/editor/EditorToolbar.ets');
const dialog = read('note/src/main/ets/ui/editor/ToolboxSettingsDialog.ets');
const fake = read('note/src/test/EditorViewModel.test.ets');
const stringsBase = read('note/src/main/resources/base/element/string.json');
const stringsZh = read('note/src/main/resources/zh_CN/element/string.json');

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };

// --- Original evidence anchors -----------------------------------------------------
const cgf = readOriginal('decompiled_1.0.3/sources/defpackage/cgf.java');
const e47 = readOriginal('decompiled_1.0.3/sources/defpackage/e47.java');
const ba8 = readOriginal('decompiled_1.0.3/sources/defpackage/ba8.java');
const gr7 = readOriginal('decompiled_1.0.3/sources/defpackage/gr7.java');
const rz1 = readOriginal('decompiled_1.0.3/sources/defpackage/rz1.java');
const a6f = readOriginal('decompiled_1.0.3/sources/defpackage/a6f.java');
const i8f = readOriginal('decompiled_1.0.3/sources/defpackage/i8f.java');
const x7f = readOriginal('decompiled_1.0.3/sources/defpackage/x7f.java');
const wb4 = readOriginal('decompiled_1.0.3/sources/defpackage/wb4.java');
const o6f = readOriginal('decompiled_1.0.3/sources/defpackage/o6f.java');
const d8f = readOriginal('decompiled_1.0.3/sources/defpackage/d8f.java');
const yne = readOriginal('decompiled_1.0.3/sources/defpackage/yne.java');
const cha = readOriginal('decompiled_1.0.3/sources/defpackage/cha.java');
const ti9 = readOriginal('decompiled_1.0.3/sources/defpackage/ti9.java');

// cgf.java:13-17 — the three tray types, ordinals 0/1/2.
ok(cgf.includes('new cgf("Primary", 0)') && cgf.includes('new cgf("Secondary", 1)') &&
   cgf.includes('new cgf("Hidden", 2)'),
  'original cgf Primary/Secondary/Hidden ordinals missing');

// e47.java — TrayEntity carries tray_id/tray_type/toolbox_owner_id/lastUsedToolId;
// ToolStateEntity carries tray_owner_id + trayIndex FK into the tray.
ok(e47.includes('new oee("TrayEntity"') && e47.includes('index_TrayEntity_toolbox_owner_id'),
  'original TrayEntity table missing');
ok(e47.includes('"tray_owner_id", new lee(0, 1, "tray_owner_id"') &&
   e47.includes('"trayIndex", new lee(0, 1, "trayIndex"'),
  'original ToolStateEntity tray_owner_id/trayIndex columns missing');

// cha.java — Room UPDATE adapter writes ToolStateEntity rows (tray membership is a
// column-level update, not a separate relation write).
ok(cha.includes('ToolStateEntity'), 'original ToolStateEntity update adapter missing');

// gr7.java/ba8.java — the seed/reset pipeline creates the toolbox plus trays
// Primary(id 0, lastUsedTool 1), Secondary(id 1, lastUsedTool 10), Hidden(id 2, -1).
ok(gr7.includes('new j7f(0, 1, 1)'), 'original ToolboxEntity(0,1,1) seed missing');
ok(gr7.includes('new agf(0, cgf.I, 0, 1)') && gr7.includes('new agf(1, cgf.J, 0, 10)') &&
   gr7.includes('new agf(2, cgf.K, 0, -1)'),
  'original three-tray seed (0/1/2) missing');

// rz1.java — default tools: Primary = 8 rows (trayOwner 0), Secondary = 5 rows
// (trayOwner 1), tool_ids seed at 1/10 so tool_id != toolType (duplicates supported).
ok(rz1.includes('new u5f(1, 0, a6f.I, 0,') && rz1.includes('new u5f(0, 0, a6f.J, 1,'),
  'original primary default tool seeds missing');
ok(rz1.includes('new u5f(10, 1, a6f.Q, 0, null') && rz1.includes('new u5f(0, 1, a6f.T, 4, null'),
  'original secondary default tool seeds missing');

// a6f.java — 13 tool types; Harmony implements a subset (PEN..SELECT equivalents).
for (const name of ['PEN', 'PENCIL', 'HIGHLIGHTER', 'TEXT', 'ERASER', 'SELECT',
                    'MEDIA', 'RECORD', 'POINTER', 'LASER', 'REVIEW', 'RULER', 'ZOOM']) {
  ok(a6f.includes(`"${name}"`), `original tool enum ${name} missing`);
}

// i8f.java — a() is the move/reorder algorithm: reindex the source tray densely,
// insert into the destination tray at rh8.v(i2,0,size) (clamped), reindex dest.
ok(i8f.includes('arrayList4.add(rh8.v(i2, 0, arrayList4.size()), u5fVar)'),
  'original clamped destination insert missing');
ok(i8f.includes('u5f.a((u5f) obj2, 0, 0, i6, null, 119)') &&
   i8f.includes('u5f.a((u5f) obj4, 0, i3, i8, null, 117)'),
  'original source/dest tray reindex masks missing');

// x7f.java — case 0 delete: refuse when <=1 instance of the tool type across
// visible trays; case 1 hide: move to the end of the Hidden tray (cgf.K).
ok(x7f.includes('Refusing to delete the sole instance of a tool type'),
  'original sole-instance delete guard missing');
ok(x7f.includes('objH = i8fVar.h(cgf.K, this)') &&
   x7f.includes('i8f.a(i8fVar, u5fVar, i7, size, this)'),
  'original hide-to-Hidden-end path missing');

// wb4.java — unhide prefers Primary while size < 12, overflows to Secondary.
ok(wb4.includes('size < 12') && wb4.includes('i8fVar.h(cgf.I, this)') &&
   wb4.includes('i8fVar.h(cgf.J, this)') &&
   wb4.includes('No Primary tray found when unhiding a tool'),
  'original unhide Primary<12->Secondary fallback missing');

// o6f.java — the settings model computes maxReached = visible size >= 12.
ok(o6f.includes('list5.size() >= 12'), 'original maxReached >=12 bound missing');

// yne.java + d8f.java + ai9.java — reset path: DELETE FROM ToolStateEntity then
// reseed; the settings VM wires the sg9 (reset) event through ai9 to d8f.
ok(yne.includes('DELETE FROM ToolStateEntity'), 'original tool-state wipe missing');
ok(d8f.includes('public Iterator J'), 'original reset use-case (d8f) missing');
const ai9 = readOriginal('decompiled_1.0.3/sources/defpackage/ai9.java');
ok(ai9.includes('new d8f(i8fVar') && ti9.includes('rh9Var instanceof sg9'),
  'original settings reset wiring (sg9->ai9->d8f) missing');

// --- Harmony schema anchors --------------------------------------------------------
ok(brush.includes('export const TRAY_TYPE_PRIMARY: number = 0;') &&
   brush.includes('export const TRAY_TYPE_SECONDARY: number = 1;') &&
   brush.includes('export const TRAY_TYPE_HIDDEN: number = 2;') &&
   brush.includes('export const MAX_PRIMARY_TOOLS: number = 12;'),
  'tray type + max constants missing');
ok(/export interface ToolState \{[\s\S]*?trayType: number;[\s\S]*?\}/.test(brush),
  'ToolState.trayType missing');
ok(/export interface EditorTray \{[\s\S]*?lastUsedToolId: string \| null;[\s\S]*?\}/.test(brush),
  'EditorTray model missing');

ok(ddl.includes('tray_type INTEGER NOT NULL DEFAULT 0,'), 'tool_state.tray_type column missing');
ok(ddl.includes('export const DDL_EDITOR_TRAY') && ddl.includes('CREATE TABLE IF NOT EXISTS editor_tray') &&
   ddl.includes('last_used_tool_id TEXT') && ddl.includes('PRIMARY KEY (tray_id, toolbox_owner_id)'),
  'editor_tray DDL missing');
ok(ddl.includes('DB_VERSION: number = 71'), 'DB_VERSION must be 71');
ok(ddl.includes('ALTER TABLE tool_state ADD COLUMN tray_type INTEGER NOT NULL DEFAULT 0') &&
   ddl.includes('INSERT OR IGNORE INTO editor_tray'),
  'v69 tray migration statements missing');
ok(dbMgr.includes('DDL_EDITOR_TRAY'), 'editor_tray not registered in ddlList');

// --- Harmony repository anchors ----------------------------------------------------
for (const name of ['getTrays', 'ensureTrays', 'setTrayLastUsedTool', 'moveToolToTray',
                    'insertToolStateAt', 'deleteAllToolStates']) {
  ok(iface.includes(`${name}(`), `ToolRepository.${name} missing from interface`);
  ok(repo.includes(`async ${name}(`), `ToolRepositoryImpl.${name} missing`);
  ok(fake.includes(`async ${name}(`), `FakeToolRepository.${name} missing`);
}
// i8f.a parity: clamped insert + dense reindex of both trays in one transaction.
ok(repo.includes('Math.max(0, Math.min(insertIndex, destTools.length))'),
  'repository clamped destination index missing');
ok(/moveToolToTray[\s\S]*?beginTransaction[\s\S]*?commit\(\)/.test(repo) &&
   /moveToolToTray[\s\S]*?reindexed\.trayIndex = index/.test(repo) &&
   /moveToolToTray[\s\S]*?reindexed\.trayType = destTrayType/.test(repo),
  'repository dual-tray dense reindex missing');
// x7f parity: deleting a row compacts its tray.
ok(/deleteToolState[\s\S]*?trayIndex = index[\s\S]*?index\+\+/.test(repo),
  'delete must reindex the source tray');
// Ordering: visible trays first, dense tray_index within each.
ok(/getToolStates[\s\S]*?orderByAsc\('tray_type'\)[\s\S]*?orderByAsc\('tray_index'\)/.test(repo),
  'getToolStates tray ordering missing');

// --- Harmony view-model anchors ----------------------------------------------------
ok(vm.includes('toolStates: ToolState[]'), 'toolStates exposure missing');
ok(vm.includes('visibleToolStates(): ToolState[]') && vm.includes('hiddenToolStates(): ToolState[]'),
  'visible/hidden partitions missing');
ok(vm.includes('async hideTool(toolId: string)') && vm.includes('TRAY_TYPE_HIDDEN'),
  'hideTool missing');
ok(vm.includes('async showTool(toolId: string)') &&
   vm.includes('this.isPrimaryTrayFull() ? TRAY_TYPE_SECONDARY : TRAY_TYPE_PRIMARY'),
  'showTool Primary<12->Secondary fallback missing');
ok(vm.includes('countTrayType(this.states, TRAY_TYPE_PRIMARY) >= MAX_PRIMARY_TOOLS'),
  'isPrimaryTrayFull 12-cap missing');
ok(vm.includes('async moveToolToIndex(toolId: string, trayType: number, index: number)'),
  'moveToolToIndex missing');
ok(vm.includes('async duplicateTool(toolId: string)') && vm.includes('uniqueToolId(') &&
   /duplicateTool[\s\S]*?copy\.trayIndex = source\.trayIndex \+ 1/.test(vm),
  'duplicateTool with fresh id + adjacent insert missing');
ok(vm.includes('async deleteTool(toolId: string)') &&
   /canDeleteTool[\s\S]*?state\.toolType === tool\.toolType && state\.trayType !== TRAY_TYPE_HIDDEN[\s\S]*?count\+\+[\s\S]*?return count > 1/.test(vm),
  'deleteTool sole-instance guard missing');
ok(vm.includes('async resetToolsToDefaults()') && vm.includes('deleteAllToolStates'),
  'resetToolsToDefaults wipe+reseed missing');
ok(vm.includes('async selectToolById(toolId: string)') &&
   vm.includes('target.trayType === TRAY_TYPE_HIDDEN'),
  'selectToolById hidden guard missing');
ok(vm.includes('isActiveTool(toolId: string)'), 'isActiveTool missing');
ok(/runStructuralOp[\s\S]*?cloneStates\(this\.states\)/.test(vm),
  'structural rollback must deep-clone the snapshot');
ok(vm.includes('fixActiveToolAfterStructuralOp'), 'post-op active-tool repair missing');
ok(vm.includes('setTrayLastUsedTool'), 'tray lastUsedToolId write missing');

// --- Harmony UI anchors ------------------------------------------------------------
ok(toolbar.includes('this.viewModel.visibleToolStates()') && /ForEach\(/.test(toolbar),
  'dynamic toolbar rendering missing');
ok(toolbar.includes('isActiveTool('), 'per-row active highlight missing');
ok(toolbar.includes('ToolboxSettingsDialog') && toolbar.includes('bindSheet'),
  'settings sheet binding missing');
ok(toolbar.includes('this.viewModel.selectToolById'), 'select-by-id wiring missing');

ok(dialog.includes('visibleToolStates()') && dialog.includes('hiddenToolStates()'),
  'dialog tray sections missing');
for (const name of ['hideTool', 'showTool', 'moveToolToIndex', 'duplicateTool',
                    'deleteTool', 'resetToolsToDefaults']) {
  ok(dialog.includes(`viewModel.${name}(`), `dialog must call ${name}`);
}
ok(dialog.includes('tool_max_reached'), 'max-reached row missing');
ok(dialog.includes('canDeleteTool'), 'delete guard surface missing');

// Resource names mirror the original's (hidden_tools, reset_to_default, ...).
for (const res of [stringsBase, stringsZh]) {
  for (const key of ['toolbox_settings', 'hidden_tools', 'show_tool', 'hide_tool',
                     'delete_tool', 'duplicate_tool', 'reset_to_default',
                     'move_tool_up', 'move_tool_down', 'tool_max_reached',
                     'move_to_primary', 'move_to_secondary']) {
    ok(res.includes(`"name": "${key}"`), `string ${key} missing`);
  }
}

// --- Executable model: i8f.a move + x7f delete/hide + wb4 unhide + gr7 reset --------
const TRAY = { PRIMARY: 0, SECONDARY: 1, HIDDEN: 2 };
const MAX_PRIMARY = 12;

function makeState(toolId, trayType, trayIndex, toolType) {
  return { toolId, trayType, trayIndex, toolType };
}
function trayOf(states, trayType) {
  return states.filter(s => s.trayType === trayType).sort((a, b) => a.trayIndex - b.trayIndex);
}
// i8f.a: reindex source, clamped insert into dest, reindex dest.
function originalMove(states, toolId, destTray, insertIndex) {
  const moved = states.find(s => s.toolId === toolId);
  if (!moved) return;
  const source = trayOf(states, moved.trayType).filter(s => s.toolId !== toolId);
  source.forEach((s, i) => { s.trayIndex = i; });
  const dest = trayOf(states, destTray).filter(s => s.toolId !== toolId);
  const clamped = Math.max(0, Math.min(insertIndex, dest.length));
  dest.splice(clamped, 0, moved);
  dest.forEach((s, i) => { s.trayType = destTray; s.trayIndex = i; });
}
// x7f case 0: refuse when <=1 instance of the type across Primary+Secondary.
function originalDelete(states, toolId) {
  const target = states.find(s => s.toolId === toolId);
  const instances = states.filter(s => s.toolType === target.toolType && s.trayType !== TRAY.HIDDEN);
  if (instances.length <= 1) return false;
  states.splice(states.indexOf(target), 1);
  trayOf(states, target.trayType).forEach((s, i) => { s.trayIndex = i; });
  return true;
}
// wb4: unhide -> end of Primary while size<12, else end of Secondary.
function originalUnhide(states, toolId) {
  const target = states.find(s => s.toolId === toolId);
  const destTray = trayOf(states, TRAY.PRIMARY).length < MAX_PRIMARY ? TRAY.PRIMARY : TRAY.SECONDARY;
  originalMove(states, target.toolId, destTray, trayOf(states, destTray).length);
}
function assertDense(states, trayType) {
  trayOf(states, trayType).forEach((s, i) => assert.equal(s.trayIndex, i));
}

let states = [
  makeState('pen', TRAY.PRIMARY, 0, 0), makeState('pencil', TRAY.PRIMARY, 1, 1),
  makeState('high', TRAY.PRIMARY, 2, 2), makeState('text', TRAY.PRIMARY, 3, 3),
  makeState('eraser', TRAY.PRIMARY, 4, 4), makeState('select', TRAY.PRIMARY, 5, 5),
  makeState('pointer', TRAY.SECONDARY, 0, 8), makeState('ruler', TRAY.SECONDARY, 1, 11),
];
// Move within a tray: pen to index 3 -> dense reindex.
originalMove(states, 'pen', TRAY.PRIMARY, 3);
assert.deepEqual(trayOf(states, TRAY.PRIMARY).map(s => s.toolId),
  ['pencil', 'high', 'text', 'pen', 'eraser', 'select']); checks++;
// Move across trays: pen Primary -> Secondary index 0.
originalMove(states, 'pen', TRAY.SECONDARY, 0);
assert.deepEqual(trayOf(states, TRAY.SECONDARY).map(s => s.toolId),
  ['pen', 'pointer', 'ruler']); checks++;
assertDense(states, TRAY.PRIMARY); checks++;
// Clamp: index 99 lands at the end.
originalMove(states, 'pen', TRAY.SECONDARY, 99);
assert.equal(trayOf(states, TRAY.SECONDARY).at(-1).toolId, 'pen'); checks++;
// Hide: moves to the end of Hidden (x7f case 1).
originalMove(states, 'ruler', TRAY.HIDDEN, trayOf(states, TRAY.HIDDEN).length);
assert.equal(trayOf(states, TRAY.HIDDEN).length, 1); checks++;
// Unhide: Primary (5 < 12) -> end of Primary.
originalUnhide(states, 'ruler');
assert.equal(trayOf(states, TRAY.PRIMARY).at(-1).toolId, 'ruler'); checks++;
// Fill Primary to 12. Hiding a Primary tool frees a slot, so refill it before
// unhiding — the hidden tool then overflows to the end of Secondary (wb4).
while (trayOf(states, TRAY.PRIMARY).length < MAX_PRIMARY) {
  states.push(makeState(`dup${trayOf(states, TRAY.PRIMARY).length}`, TRAY.PRIMARY,
    trayOf(states, TRAY.PRIMARY).length, 0));
}
originalMove(states, 'pencil', TRAY.HIDDEN, 0);
states.push(makeState('filler', TRAY.PRIMARY, trayOf(states, TRAY.PRIMARY).length, 0));
originalUnhide(states, 'pencil');
assert.equal(trayOf(states, TRAY.SECONDARY).at(-1).toolId, 'pencil'); checks++;
assertDense(states, TRAY.PRIMARY); checks++;
// Sole-instance guard: deleting the only pencil-visible instance is refused.
assert.equal(originalDelete(states, 'pencil'), false); checks++;
// Duplicate instance can be deleted and the tray compacts.
states.push(makeState('pencil2', TRAY.SECONDARY, trayOf(states, TRAY.SECONDARY).length, 1));
assert.equal(originalDelete(states, 'pencil2'), true); checks++;
assertDense(states, TRAY.SECONDARY); checks++;

console.log(`D02_ORIGINAL_TOOLBOX_CUSTOMIZATION_OK TOTAL=${checks} FAILED=0`);
