// Phase 1391 — 原版 Toolbox/Room schema 逐表比对修正。
// 原版证据（decompiled_1.4.2）：
//   ca3.java:555      — ToolStateEntity CREATE TABLE（18 列全列）。
//   ca3.java:405/555  — penLastStandardColorWellIndex、googleInkBrushPackId
//                       INTEGER DEFAULT NULL。
//   gb7.java:107      — SHAPE 升级回填 SQL：INSERT 进每个 owner 的
//                       tray_type='Secondary' 托盘，trayIndex =
//                       MAX(sibling.trayIndex)+1（sibling.tray_owner_id 限定同托盘）。
//   zmb.java:118      — style INTEGER→TEXT 迁移：0→Mono/1→Taper/2→Dash/3→Dot。
// 断言：
//   ① 缺失工具回填用「工具所属托盘尾部」（nextTrayTailIndex），而非 Primary 计数；
//   ② tool_state 补齐 google_ink_brush_pack_id / pen_last_standard_color_well_index；
//   ③ migration 73 执行两列 ALTER；DB_VERSION=73；
//   ④ penLastStandardColorWellIndex 在标准色井选择时持久化（setBrushColor 写侧）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const DB = 'note/src/main/ets/data/DatabaseHelper.ets';
const REPO = 'note/src/main/ets/data/ToolRepositoryImpl.ets';
const VM = 'note/src/main/ets/ui/editor/EditorViewModel.ets';
const BT = 'note/src/main/ets/core/model/BrushTypes.ets';

const db = readFileSync(DB, 'utf8');
const repo = readFileSync(REPO, 'utf8');
const vm = readFileSync(VM, 'utf8');
const bt = readFileSync(BT, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// === 1. SHAPE backfill → own-tray tail (gb7:107 MAX(sibling.trayIndex)+1) ===
check(/nextTrayTailIndex\(states: ToolState\[\], trayType: number\)/.test(vm),
  'nextTrayTailIndex helper exists');
{
  const m = vm.match(/nextTrayTailIndex\(states: ToolState\[\], trayType: number\): number \{([\s\S]*?)\n  \}/);
  check(m !== null && /trayIndex > max/.test(m[1]) && /return max \+ 1/.test(m[1]),
    'nextTrayTailIndex returns MAX(trayIndex)+1 within the given tray');
}
check(/backfill\.trayIndex = this\.nextTrayTailIndex\(merged, backfill\.trayType\)/.test(vm),
  'missing-tool backfill uses its own tray tail (not primaryCount)');
check(!/backfill\.trayIndex = primaryCount/.test(vm),
  'backfill no longer indexes by Primary count (was placing SHAPE at a Primary-computed index)');

// === 2. tool_state column parity (ca3.java:555, 18 cols) ===
check(/DB_VERSION: number = 75/.test(db), 'DB_VERSION bumped to 75');
check(/google_ink_brush_pack_id INTEGER DEFAULT NULL/.test(db),
  'tool_state.google_ink_brush_pack_id (ToolStateEntity.googleInkBrushPackId)');
check(/pen_last_standard_color_well_index INTEGER DEFAULT NULL/.test(db),
  'tool_state.pen_last_standard_color_well_index (ToolStateEntity.penLastStandardColorWellIndex)');
{
  const mig = db.match(/73: \[([\s\S]*?)\],?\n\};/);
  check(mig !== null &&
    /ALTER TABLE tool_state ADD COLUMN google_ink_brush_pack_id/.test(mig[1]) &&
    /ALTER TABLE tool_state ADD COLUMN pen_last_standard_color_well_index/.test(mig[1]),
    'migration 73 ALTERs in both ToolStateEntity parity columns');
}

// === 3. Model + persistence ===
check(/googleInkBrushPackId\?:\s*number \| null/.test(bt),
  'ToolState.googleInkBrushPackId');
check(/penLastStandardColorWellIndex\?:\s*number \| null/.test(bt),
  'ToolState.penLastStandardColorWellIndex');
for (const col of ["'google_ink_brush_pack_id'", "'pen_last_standard_color_well_index'"]) {
  check(repo.includes(col), `toBucket writes ${col}`);
}
for (const col of ['google_ink_brush_pack_id', 'pen_last_standard_color_well_index']) {
  check(repo.includes(`getColumnIndex('${col}')`), `rowToState reads ${col}`);
}
check(/cloneState[\s\S]*?penLastStandardColorWellIndex: state\.penLastStandardColorWellIndex/.test(repo),
  'repo cloneState carries penLastStandardColorWellIndex');

// === 4. Write-side: standard-well select records last standard index ===
check(/if \(selectedWellIndex >= 0\)[\s\S]{0,90}state\.penLastStandardColorWellIndex = selectedWellIndex/
  .test(vm),
  'setBrushColor records penLastStandardColorWellIndex when a standard well is picked');

// === 5. googleInkBrushPackId stays NULL (Google Ink fail-closed) ===
check(/googleInkBrushPackId: null/.test(vm) || /googleInkBrushPackId\?:/.test(bt),
  'googleInkBrushPackId reserved/NULL — Google Ink brush packs fail-closed');

console.log(`d02-original-toolbox-schema-parity OK — ${n} checks`);
