import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const desktop = 'C:/Users/Cisco He/Desktop/Notability/';
const readOriginal = path => fs.readFileSync(desktop + path, 'utf8');

const ddl = read('note/src/main/ets/data/DatabaseHelper.ets');
const manager = read('note/src/main/ets/data/DatabaseManager.ets');
const iface = read('note/src/main/ets/data/RepositoryInterfaces.ets');
const repo = read('note/src/main/ets/data/ToolRepositoryImpl.ets');
const vm = read('note/src/main/ets/ui/editor/EditorViewModel.ets');
const colorPicker = read('note/src/main/ets/ui/components/ColorPicker.ets');
const widthSlider = read('note/src/main/ets/ui/components/WidthSlider.ets');
const fixture = read('note/src/test/DatabaseHelper.test.ets');
const fakeRepo = read('note/src/test/EditorViewModel.test.ets');

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };
const eq = (a, b, label) => { assert.equal(a, b, label); checks++; };

// --- Original evidence anchors -----------------------------------------------------
const e47 = readOriginal('decompiled_1.0.3/sources/defpackage/e47.java');
const rz1 = readOriginal('decompiled_1.0.3/sources/defpackage/rz1.java');
const ehb = readOriginal('decompiled_1.0.3/sources/defpackage/ehb.java');
const i8f = readOriginal('decompiled_1.0.3/sources/defpackage/i8f.java');
const tb4 = readOriginal('decompiled_1.0.3/sources/defpackage/tb4.java');
const m2a = readOriginal('decompiled_1.0.3/sources/defpackage/m2a.java');
const gr7 = readOriginal('decompiled_1.0.3/sources/defpackage/gr7.java');
const wp1 = readOriginal('decompiled_1.0.3/sources/defpackage/wp1.java');

// e47.java:377-382 — the three well entities the original ToolboxDatabase declares.
ok(e47.includes('CREATE TABLE IF NOT EXISTS `FavoriteColorWellEntity`'),
  'original FavoriteColorWellEntity DDL missing');
ok(e47.includes('`toolType` TEXT NOT NULL, `color` INTEGER NOT NULL, `trayIndex` INTEGER NOT NULL'),
  'original FavoriteColorWellEntity columns missing');
ok(e47.includes('CREATE TABLE IF NOT EXISTS `WidthSizeWellEntity`'),
  'original WidthSizeWellEntity DDL missing');
ok(e47.includes('`width` REAL NOT NULL'), 'original width column missing');
ok(e47.includes('CREATE TABLE IF NOT EXISTS `RecentColorWellEntity`'),
  'original RecentColorWellEntity DDL missing');
ok(e47.includes('`color` INTEGER NOT NULL, `timestamp` INTEGER NOT NULL'),
  'original recent columns missing');

// wp1.java:552 — ToolStateEntity column order puts selectedColorWellIndex before
// selectedWidthSizeWellIndex inside the embedded brush.
ok(wp1.includes('`selectedColorWellIndex`,`selectedWidthSizeWellIndex`'),
  'original ToolStateEntity selected-well columns missing');

// rz1.java:1044-1097 — original default seed data.
ok(rz1.includes('new qb4(0, a6fVar, -16777216, 0)') &&
   rz1.includes('new qb4(0, a6fVar, -15260469, 1)') &&
   rz1.includes('new qb4(0, a6fVar, -2011583, 2)'),
  'original PEN favorite defaults missing');
ok(rz1.includes('new qb4(0, a6fVar3, -172, 0)'), 'original HIGHLIGHTER favorite defaults missing');
ok(rz1.includes('new qb4(0, a6fVar5, -1706497, 0)'), 'original REVIEW favorite defaults missing');
ok(rz1.includes('new j6g(0, a6fVar, 1.0f, 0)') &&
   rz1.includes('new j6g(0, a6fVar, 2.0f, 1)') &&
   rz1.includes('new j6g(0, a6fVar, 4.0f, 2)'),
  'original PEN width defaults missing');
ok(rz1.includes('new j6g(0, a6fVar3, 20.0f, 0)') &&
   rz1.includes('new j6g(0, a6fVar3, 15.0f, 1)') &&
   rz1.includes('new j6g(0, a6fVar3, 10.0f, 2)'),
  'original HIGHLIGHTER width defaults missing');
ok(rz1.includes('new j6g(0, a6fVar4, 4.0f, 0)') &&
   rz1.includes('new j6g(0, a6fVar4, 7.5f, 1)') &&
   rz1.includes('new j6g(0, a6fVar4, 15.0f, 2)'),
  'original ERASER width defaults missing');

// gr7.java — original seeds favorites + widths + tool states at toolbox init.
ok(gr7.includes('rz1.p()') && gr7.includes('rz1.s()'),
  'original first-run well seeding missing');

// i8f.java — favorite upsert keeps id at (toolType, trayIndex); read self-heals
// non-dense indices by rewriting trayIndex = position.
ok(i8f.includes('qb4Var.d >= list.size()'), 'original dense-index self-heal missing');
ok(i8f.includes('qb4.a((qb4) obj, 0, i3, 7)'), 'original reindex rewrite missing');
ok(i8f.includes('new qb4(0, a6fVar, i2, i)'), 'original favorite insert missing');

// tb4.java — favorite delete shifts trayIndex down past the removed slot.
ok(tb4.includes('trayIndex = trayIndex - 1 WHERE trayIndex > ? AND toolType = ?'),
  'original favorite delete shift-down missing');

// ehb.java — recents dedupe by color, refresh timestamp on reuse, cap at 7
// (count >= 7 deletes the oldest count-6 rows before inserting).
ok(ehb.includes('iIntValue >= 7'), 'original recents cap-7 missing');
ok(ehb.includes('iIntValue - 6'), 'original recents trim-to-6 missing');

// m2a.java:139 — recents read newest first.
ok(m2a.includes('ORDER BY timestamp DESC'), 'original recents DESC ordering missing');

// --- Harmony schema anchors --------------------------------------------------------
ok(ddl.includes('CREATE TABLE IF NOT EXISTS favorite_color_well'),
  'favorite_color_well DDL missing');
ok(/favorite_color_well[\s\S]*?tool_type INTEGER NOT NULL/.test(ddl),
  'favorite_color_well.tool_type missing');
ok(/favorite_color_well[\s\S]*?color INTEGER NOT NULL/.test(ddl),
  'favorite_color_well.color missing');
ok(/favorite_color_well[\s\S]*?tray_index INTEGER NOT NULL/.test(ddl),
  'favorite_color_well.tray_index missing');
ok(ddl.includes('CREATE TABLE IF NOT EXISTS width_size_well'),
  'width_size_well DDL missing');
ok(/width_size_well[\s\S]*?width REAL NOT NULL/.test(ddl), 'width_size_well.width missing');
ok(ddl.includes('CREATE TABLE IF NOT EXISTS recent_color_well'),
  'recent_color_well DDL missing');
ok(/recent_color_well[\s\S]*?timestamp INTEGER NOT NULL/.test(ddl),
  'recent_color_well.timestamp missing');
ok(manager.includes('DDL_FAVORITE_COLOR_WELL') &&
   manager.includes('DDL_WIDTH_SIZE_WELL') &&
   manager.includes('DDL_RECENT_COLOR_WELL'),
  'DatabaseManager must create all three well tables');

// Well tables ship via the canonical DDL idempotent path — no version bump needed for
// them (same as Phase 530's tool_state index). DB_VERSION moved to 69 in Phase 534 for
// the folder color/emoji/updated_at column migration.
ok(ddl.includes('DB_VERSION: number = 69'), 'DB_VERSION must be 69');

// --- Harmony interface + repository anchors ----------------------------------------
for (const name of ['getFavoriteColors', 'setFavoriteColor', 'removeFavoriteColor',
  'getWidthWells', 'setWidthWell', 'removeWidthWell',
  'getRecentColors', 'recordRecentColor', 'seedDefaultToolWells']) {
  ok(iface.includes(name), `ToolRepository.${name} missing`);
  ok(repo.includes(name), `ToolRepositoryImpl.${name} missing`);
}

// Default seeds mirror rz1.p()/s() mapped onto Harmony ToolType.
ok(repo.includes('DEFAULT_FAVORITE_WELLS') && repo.includes('DEFAULT_WIDTH_WELLS'),
  'default well seed tables missing');
for (const color of ['-16777216', '-15260469', '-2011583']) {
  ok(repo.includes(`ToolType.PEN, values: [-16777216, -15260469, -2011583]`) ||
     repo.includes(color), 'PEN favorite defaults missing');
}
ok(repo.includes('ToolType.HIGHLIGHTER, values: [-172, -4391597, -1428530]'),
  'HIGHLIGHTER favorite defaults missing');
ok(repo.includes('ToolType.REVIEW, values: [-1706497, -672330, -6303021, -11872, -2238485]'),
  'REVIEW favorite defaults missing');
ok(repo.includes('ToolType.PEN, values: [1.0, 2.0, 4.0]'), 'PEN width defaults missing');
ok(repo.includes('ToolType.PENCIL, values: [1.5, 3.0, 5.0]'), 'PENCIL width defaults missing');
ok(repo.includes('ToolType.HIGHLIGHTER, values: [20.0, 15.0, 10.0]'),
  'HIGHLIGHTER width defaults missing');
ok(repo.includes('ToolType.WHOLE_ERASER, values: [4.0, 7.5, 15.0]'),
  'ERASER width defaults missing');
ok(repo.includes('ToolType.REVIEW, values: [12.0, 36.0, 64.0]'),
  'REVIEW width defaults missing');

// Recents cap-7 + dedupe + timestamp DESC parity.
ok(repo.includes('RECENT_COLOR_LIMIT: number = 7'), 'recents cap constant missing');
ok(repo.includes('WHERE color = ?'), 'recents dedupe query missing');
ok(repo.includes('ORDER BY timestamp DESC'), 'recents DESC read missing');
ok(repo.includes('ORDER BY timestamp ASC LIMIT ?'), 'recents oldest-trim missing');
ok(repo.includes('count - RECENT_COLOR_LIMIT + 1'), 'recents trim arithmetic missing');

// Favorite delete shift-down + dense-index read heal parity.
ok(repo.includes('tray_index = tray_index - 1 WHERE tray_index > ? AND tool_type = ?'),
  'favorite delete shift-down missing');
ok(repo.includes('healWellRows'), 'dense-index read heal missing');
ok(repo.includes('rows[rows.length - 1].trayIndex < rows.length'),
  'heal guard must mirror original last.trayIndex >= size check');

// --- ViewModel + UI wiring anchors ---------------------------------------------------
ok(vm.includes('favoriteColors: number[] = []'), 'viewModel favoriteColors field missing');
ok(vm.includes('recentColors: number[] = []'), 'viewModel recentColors field missing');
ok(vm.includes('widthWells: number[] = []'), 'viewModel widthWells field missing');
ok(vm.includes('seedDefaultToolWells()'), 'initialize must seed default wells');
ok(vm.includes('refreshWells'), 'viewModel refreshWells missing');
ok(vm.includes('recordRecentColor(color)'), 'setBrushColor must record recents');
ok(vm.includes('selectedWellIndex: number = -1'),
  'non-well picks must deselect the well index');
ok(colorPicker.includes('viewModel.favoriteColors'), 'picker must render favorite wells');
ok(colorPicker.includes('viewModel.recentColors'), 'picker must render recents');
ok(colorPicker.includes('onWellColor(color, index)'), 'well taps must carry the well index');
ok(widthSlider.includes('viewModel.widthWells'), 'slider must render width wells');
ok(widthSlider.includes('setBrushWidth(width, index)'), 'width well taps must carry index');

// Fixture + fake coverage.
ok(fixture.includes('DDL_FAVORITE_COLOR_WELL') && fixture.includes('DDL_RECENT_COLOR_WELL'),
  'DatabaseHelper fixture must assert the well tables');
ok(fakeRepo.includes('seedDefaultToolWells') && fakeRepo.includes('recordRecentColor'),
  'FakeToolRepository must implement the well methods');

// --- Executable semantics model ------------------------------------------------------
// Mirror ehb: recents dedupe by color (timestamp refresh = move to front), cap 7.
{
  const recents = [];
  let now = 0;
  const record = (color) => {
    now++;
    const at = recents.findIndex(r => r.color === color);
    if (at >= 0) {
      recents[at].timestamp = now;
    } else {
      if (recents.length >= 7) {
        recents.sort((a, b) => b.timestamp - a.timestamp);
        recents.splice(6, recents.length - 6);
      }
      recents.push({ color, timestamp: now });
    }
    recents.sort((a, b) => b.timestamp - a.timestamp);
  };
  [10, 20, 30, 40, 50, 60, 70].forEach(record);
  eq(recents.length, 7, 'recents hold the first seven distinct colors');
  record(80);
  eq(recents.length, 7, 'recents stay capped at 7');
  eq(recents[0].color, 80, 'newest color first');
  eq(recents.findIndex(r => r.color === 10), -1, 'oldest color evicted');
  eq(recents[recents.length - 1].color, 20, 'second-oldest survives at the tail');
  record(20);
  eq(recents[0].color, 20, 'reused color refreshes to the front');
  eq(recents.length, 7, 'reuse keeps the cap');
  eq(recents.filter(r => r.color === 20).length, 1, 'recents dedupe by color');
}

// Mirror i8f + tb4: upsert at (toolType, trayIndex) preserving id; delete shifts
// indices down; read heals non-dense indices.
{
  let nextId = 1;
  const wells = [];
  const upsert = (toolType, trayIndex, color) => {
    const found = wells.find(w => w.toolType === toolType && w.trayIndex === trayIndex);
    if (found) {
      found.color = color;
    } else {
      wells.push({ id: nextId++, toolType, color, trayIndex });
    }
  };
  const remove = (toolType, trayIndex) => {
    for (const w of wells) {
      if (w.toolType === toolType && w.trayIndex > trayIndex) {
        w.trayIndex -= 1;
      }
    }
    const at = wells.findIndex(w => w.toolType === toolType && w.trayIndex === trayIndex);
    if (at >= 0) wells.splice(at, 1);
  };
  const readWells = (toolType) => {
    const rows = wells.filter(w => w.toolType === toolType)
      .sort((a, b) => a.trayIndex - b.trayIndex);
    if (rows.length > 0 && rows[rows.length - 1].trayIndex >= rows.length) {
      rows.forEach((row, i) => { row.trayIndex = i; });
    }
    return rows.map(r => r.color);
  };
  upsert(3, 0, -16777216);
  upsert(3, 1, -15260469);
  upsert(3, 2, -2011583);
  upsert(5, 0, -16777216);
  eq(readWells(3).join(), '-16777216,-15260469,-2011583', 'PEN wells seed order');
  eq(readWells(5).join(), '-16777216', 'per-tool isolation');
  upsert(3, 1, -65536);
  eq(readWells(3)[1], -65536, 'upsert replaces color at the slot');
  eq(wells.filter(w => w.toolType === 3).length, 3, 'upsert keeps id, no new row');
  remove(3, 0);
  eq(readWells(3).join(), '-65536,-2011583', 'delete shifts later wells down');
  // Simulate a non-dense table (legacy deletes without shift): read must self-heal.
  wells.push({ id: nextId++, toolType: 4, color: -172, trayIndex: 5 });
  eq(readWells(4).join(), '-172', 'non-dense read still returns values in order');
  eq(wells.find(w => w.toolType === 4).trayIndex, 0, 'read heal rewrites dense index');
}

console.log(`D02_ORIGINAL_TOOL_WELLS_PARITY_OK TOTAL=${checks} FAILED=0`);
